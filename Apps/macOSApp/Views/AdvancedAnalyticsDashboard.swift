import SwiftUI
import Charts
import SwiftData

@available(macOS 15.0, *)
struct AdvancedAnalyticsDashboard: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var healthRecords: [HealthData]
    @Query private var sleepSessions: [SleepSession]
    @Query private var workoutRecords: [WorkoutRecord]
    
    @State private var selectedTimeRange: TimeRange = .week
    @State private var selectedMetrics: Set<HealthMetric> = [.heartRate, .sleep, .activity]
    @State private var showingExportSheet = false
    @State private var showingSettings = false
    
    var body: some View {
        NavigationSplitView {
            SidebarView(
                selectedTimeRange: $selectedTimeRange,
                selectedMetrics: $selectedMetrics
            )
        } content: {
            AnalyticsContentView(
                healthRecords: filteredHealthRecords,
                sleepSessions: filteredSleepSessions,
                workoutRecords: filteredWorkoutRecords,
                selectedTimeRange: selectedTimeRange,
                selectedMetrics: selectedMetrics
            )
        } detail: {
            DetailAnalyticsView(
                healthRecords: filteredHealthRecords,
                sleepSessions: filteredSleepSessions,
                workoutRecords: filteredWorkoutRecords
            )
        }
        .navigationTitle("Health Analytics")
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                Button("Export") {
                    showingExportSheet = true
                }
                
                Button("Settings") {
                    showingSettings = true
                }
            }
        }
        .sheet(isPresented: $showingExportSheet) {
            ExportAnalyticsView(healthRecords: filteredHealthRecords)
        }
        .sheet(isPresented: $showingSettings) {
            AnalyticsSettingsView()
        }
    }
    
    private var filteredHealthRecords: [HealthData] {
        healthRecords.filter { record in
            record.timestamp >= selectedTimeRange.startDate
        }
    }
    
    private var filteredSleepSessions: [SleepSession] {
        sleepSessions.filter { session in
            session.startTime >= selectedTimeRange.startDate
        }
    }
    
    private var filteredWorkoutRecords: [WorkoutRecord] {
        workoutRecords.filter { record in
            record.startTime >= selectedTimeRange.startDate
        }
    }
}

// MARK: - Sidebar View

@available(macOS 15.0, *)
struct SidebarView: View {
    @Binding var selectedTimeRange: TimeRange
    @Binding var selectedMetrics: Set<HealthMetric>
    
    var body: some View {
        List {
            Section("Time Range") {
                ForEach(TimeRange.allCases, id: \.self) { range in
                    HStack {
                        Text(range.displayName)
                        Spacer()
                        if selectedTimeRange == range {
                            Image(systemName: "checkmark")
                                .foregroundColor(.blue)
                        }
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        selectedTimeRange = range
                    }
                }
            }
            
            Section("Metrics") {
                ForEach(HealthMetric.allCases, id: \.self) { metric in
                    HStack {
                        Image(systemName: metric.icon)
                            .foregroundColor(metric.color)
                        Text(metric.displayName)
                        Spacer()
                        if selectedMetrics.contains(metric) {
                            Image(systemName: "checkmark")
                                .foregroundColor(.blue)
                        }
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        if selectedMetrics.contains(metric) {
                            selectedMetrics.remove(metric)
                        } else {
                            selectedMetrics.insert(metric)
                        }
                    }
                }
            }
            
            Section("Quick Actions") {
                Button("Generate Report") {
                    // TODO: Generate comprehensive health report
                }
                
                Button("Compare Periods") {
                    // TODO: Show period comparison view
                }
                
                Button("Trend Analysis") {
                    // TODO: Show trend analysis view
                }
            }
        }
        .listStyle(SidebarListStyle())
    }
}

// MARK: - Analytics Content View

@available(macOS 15.0, *)
struct AnalyticsContentView: View {
    let healthRecords: [HealthData]
    let sleepSessions: [SleepSession]
    let workoutRecords: [WorkoutRecord]
    let selectedTimeRange: TimeRange
    let selectedMetrics: Set<HealthMetric>
    
    var body: some View {
        ScrollView {
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 20) {
                
                if selectedMetrics.contains(.heartRate) {
                    HeartRateAnalyticsCard(healthRecords: healthRecords)
                }
                
                if selectedMetrics.contains(.sleep) {
                    SleepAnalyticsCard(sleepSessions: sleepSessions)
                }
                
                if selectedMetrics.contains(.activity) {
                    ActivityAnalyticsCard(workoutRecords: workoutRecords)
                }
                
                if selectedMetrics.contains(.respiratory) {
                    RespiratoryAnalyticsCard(healthRecords: healthRecords)
                }
                
                if selectedMetrics.contains(.mental) {
                    MentalHealthAnalyticsCard(healthRecords: healthRecords)
                }
                
                if selectedMetrics.contains(.nutrition) {
                    NutritionAnalyticsCard(healthRecords: healthRecords)
                }
            }
            .padding()
        }
    }
}

// MARK: - Analytics Cards

@available(macOS 15.0, *)
struct HeartRateAnalyticsCard: View {
    let healthRecords: [HealthData]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "heart.fill")
                    .foregroundColor(.red)
                Text("Heart Rate Analytics")
                    .font(.headline)
                Spacer()
            }
            
            if !healthRecords.isEmpty {
                Chart(healthRecords) { record in
                    LineMark(
                        x: .value("Time", record.timestamp),
                        y: .value("Heart Rate", record.heartRate)
                    )
                    .foregroundStyle(.red)
                    
                    AreaMark(
                        x: .value("Time", record.timestamp),
                        y: .value("Heart Rate", record.heartRate)
                    )
                    .foregroundStyle(.red.opacity(0.1))
                }
                .frame(height: 200)
                
                HStack {
                    VStack(alignment: .leading) {
                        Text("Average")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("\(Int(averageHeartRate)) BPM")
                            .font(.title2)
                            .fontWeight(.semibold)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing) {
                        Text("Max")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("\(Int(maxHeartRate)) BPM")
                            .font(.title2)
                            .fontWeight(.semibold)
                    }
                }
            } else {
                Text("No heart rate data available")
                    .foregroundColor(.secondary)
                    .frame(height: 200)
            }
        }
        .padding()
        .background(Color(.windowBackgroundColor))
        .cornerRadius(12)
    }
    
    private var averageHeartRate: Double {
        let rates = healthRecords.compactMap { $0.heartRate }
        return rates.isEmpty ? 0 : rates.reduce(0, +) / Double(rates.count)
    }
    
    private var maxHeartRate: Double {
        healthRecords.compactMap { $0.heartRate }.max() ?? 0
    }
}

@available(macOS 15.0, *)
struct SleepAnalyticsCard: View {
    let sleepSessions: [SleepSession]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "bed.double.fill")
                    .foregroundColor(.purple)
                Text("Sleep Analytics")
                    .font(.headline)
                Spacer()
            }
            
            if !sleepSessions.isEmpty {
                Chart(sleepSessions) { session in
                    BarMark(
                        x: .value("Date", session.startTime, unit: .day),
                        y: .value("Duration", session.duration / 3600)
                    )
                    .foregroundStyle(.purple)
                }
                .frame(height: 200)
                
                HStack {
                    VStack(alignment: .leading) {
                        Text("Average Sleep")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("\(String(format: "%.1f", averageSleepHours)) hours")
                            .font(.title2)
                            .fontWeight(.semibold)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing) {
                        Text("Sleep Score")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("\(Int(averageSleepScore))")
                            .font(.title2)
                            .fontWeight(.semibold)
                    }
                }
            } else {
                Text("No sleep data available")
                    .foregroundColor(.secondary)
                    .frame(height: 200)
            }
        }
        .padding()
        .background(Color(.windowBackgroundColor))
        .cornerRadius(12)
    }
    
    private var averageSleepHours: Double {
        let durations = sleepSessions.map { $0.duration }
        return durations.isEmpty ? 0 : durations.reduce(0, +) / Double(durations.count) / 3600
    }
    
    private var averageSleepScore: Double {
        let scores = sleepSessions.compactMap { $0.sleepScore }
        return scores.isEmpty ? 0 : scores.reduce(0, +) / Double(scores.count)
    }
}

@available(macOS 15.0, *)
struct ActivityAnalyticsCard: View {
    let workoutRecords: [WorkoutRecord]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "figure.run")
                    .foregroundColor(.green)
                Text("Activity Analytics")
                    .font(.headline)
                Spacer()
            }
            
            if !workoutRecords.isEmpty {
                Chart(workoutRecords) { record in
                    BarMark(
                        x: .value("Date", record.startTime, unit: .day),
                        y: .value("Duration", record.duration / 60)
                    )
                    .foregroundStyle(.green)
                }
                .frame(height: 200)
                
                HStack {
                    VStack(alignment: .leading) {
                        Text("Total Workouts")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("\(workoutRecords.count)")
                            .font(.title2)
                            .fontWeight(.semibold)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing) {
                        Text("Avg Duration")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("\(Int(averageWorkoutDuration)) min")
                            .font(.title2)
                            .fontWeight(.semibold)
                    }
                }
            } else {
                Text("No activity data available")
                    .foregroundColor(.secondary)
                    .frame(height: 200)
            }
        }
        .padding()
        .background(Color(.windowBackgroundColor))
        .cornerRadius(12)
    }
    
    private var averageWorkoutDuration: Double {
        let durations = workoutRecords.map { $0.duration }
        return durations.isEmpty ? 0 : durations.reduce(0, +) / Double(durations.count) / 60
    }
}

@available(macOS 15.0, *)
struct RespiratoryAnalyticsCard: View {
    let healthRecords: [HealthData]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "lungs.fill")
                    .foregroundColor(.blue)
                Text("Respiratory Analytics")
                    .font(.headline)
                Spacer()
            }
            
            if !healthRecords.isEmpty {
                Chart(healthRecords) { record in
                    LineMark(
                        x: .value("Time", record.timestamp),
                        y: .value("O2 Saturation", record.oxygenSaturation ?? 0)
                    )
                    .foregroundStyle(.blue)
                }
                .frame(height: 200)
                
                HStack {
                    VStack(alignment: .leading) {
                        Text("Avg O₂ Sat")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("\(String(format: "%.1f", averageO2Saturation))%")
                            .font(.title2)
                            .fontWeight(.semibold)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing) {
                        Text("Breathing Rate")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("\(String(format: "%.1f", averageBreathingRate)) bpm")
                            .font(.title2)
                            .fontWeight(.semibold)
                    }
                }
            } else {
                Text("No respiratory data available")
                    .foregroundColor(.secondary)
                    .frame(height: 200)
            }
        }
        .padding()
        .background(Color(.windowBackgroundColor))
        .cornerRadius(12)
    }
    
    private var averageO2Saturation: Double {
        let saturations = healthRecords.compactMap { $0.oxygenSaturation }
        return saturations.isEmpty ? 0 : saturations.reduce(0, +) / Double(saturations.count)
    }
    
    private var averageBreathingRate: Double {
        let rates = healthRecords.compactMap { $0.breathingRate }
        return rates.isEmpty ? 0 : rates.reduce(0, +) / Double(rates.count)
    }
}

@available(macOS 15.0, *)
struct MentalHealthAnalyticsCard: View {
    let healthRecords: [HealthData]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "brain.head.profile")
                    .foregroundColor(.orange)
                Text("Mental Health Analytics")
                    .font(.headline)
                Spacer()
            }
            
            if !healthRecords.isEmpty {
                Chart(healthRecords) { record in
                    LineMark(
                        x: .value("Time", record.timestamp),
                        y: .value("Stress Level", record.stressLevel ?? 0)
                    )
                    .foregroundStyle(.orange)
                }
                .frame(height: 200)
                
                HStack {
                    VStack(alignment: .leading) {
                        Text("Avg Stress")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("\(String(format: "%.1f", averageStressLevel))")
                            .font(.title2)
                            .fontWeight(.semibold)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing) {
                        Text("Mood Score")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("\(String(format: "%.1f", averageMoodScore))")
                            .font(.title2)
                            .fontWeight(.semibold)
                    }
                }
            } else {
                Text("No mental health data available")
                    .foregroundColor(.secondary)
                    .frame(height: 200)
            }
        }
        .padding()
        .background(Color(.windowBackgroundColor))
        .cornerRadius(12)
    }
    
    private var averageStressLevel: Double {
        let stressLevels = healthRecords.compactMap { $0.stressLevel }
        return stressLevels.isEmpty ? 0 : stressLevels.reduce(0, +) / Double(stressLevels.count)
    }
    
    private var averageMoodScore: Double {
        let moodScores = healthRecords.compactMap { $0.moodScore }
        return moodScores.isEmpty ? 0 : moodScores.reduce(0, +) / Double(moodScores.count)
    }
}

@available(macOS 15.0, *)
struct NutritionAnalyticsCard: View {
    let healthRecords: [HealthData]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "fork.knife")
                    .foregroundColor(.brown)
                Text("Nutrition Analytics")
                    .font(.headline)
                Spacer()
            }
            
            if !healthRecords.isEmpty {
                Chart(healthRecords) { record in
                    LineMark(
                        x: .value("Time", record.timestamp),
                        y: .value("Calories", record.caloriesConsumed ?? 0)
                    )
                    .foregroundStyle(.brown)
                }
                .frame(height: 200)
                
                HStack {
                    VStack(alignment: .leading) {
                        Text("Avg Calories")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("\(Int(averageCalories))")
                            .font(.title2)
                            .fontWeight(.semibold)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing) {
                        Text("Water Intake")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("\(String(format: "%.1f", averageWaterIntake))L")
                            .font(.title2)
                            .fontWeight(.semibold)
                    }
                }
            } else {
                Text("No nutrition data available")
                    .foregroundColor(.secondary)
                    .frame(height: 200)
            }
        }
        .padding()
        .background(Color(.windowBackgroundColor))
        .cornerRadius(12)
    }
    
    private var averageCalories: Double {
        let calories = healthRecords.compactMap { $0.caloriesConsumed }
        return calories.isEmpty ? 0 : calories.reduce(0, +) / Double(calories.count)
    }
    
    private var averageWaterIntake: Double {
        let waterIntake = healthRecords.compactMap { $0.waterIntake }
        return waterIntake.isEmpty ? 0 : waterIntake.reduce(0, +) / Double(waterIntake.count)
    }
}

// MARK: - Detail Analytics View

@available(macOS 15.0, *)
struct DetailAnalyticsView: View {
    let healthRecords: [HealthData]
    let sleepSessions: [SleepSession]
    let workoutRecords: [WorkoutRecord]
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Summary Statistics
                SummaryStatisticsView(
                    healthRecords: healthRecords,
                    sleepSessions: sleepSessions,
                    workoutRecords: workoutRecords
                )
                
                // Trend Analysis
                TrendAnalysisView(healthRecords: healthRecords)
                
                // Correlation Analysis
                CorrelationAnalysisView(
                    healthRecords: healthRecords,
                    sleepSessions: sleepSessions
                )
            }
            .padding()
        }
    }
}

@available(macOS 15.0, *)
struct SummaryStatisticsView: View {
    let healthRecords: [HealthData]
    let sleepSessions: [SleepSession]
    let workoutRecords: [WorkoutRecord]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Summary Statistics")
                .font(.title2)
                .fontWeight(.semibold)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                StatisticCard(
                    title: "Data Points",
                    value: "\(healthRecords.count)",
                    icon: "chart.bar.fill",
                    color: .blue
                )
                
                StatisticCard(
                    title: "Sleep Sessions",
                    value: "\(sleepSessions.count)",
                    icon: "bed.double.fill",
                    color: .purple
                )
                
                StatisticCard(
                    title: "Workouts",
                    value: "\(workoutRecords.count)",
                    icon: "figure.run",
                    color: .green
                )
            }
        }
        .padding()
        .background(Color(.windowBackgroundColor))
        .cornerRadius(12)
    }
}

@available(macOS 15.0, *)
struct StatisticCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundColor(color)
                .font(.title2)
            
            Text(value)
                .font(.title)
                .fontWeight(.bold)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.controlBackgroundColor))
        .cornerRadius(8)
    }
}

@available(macOS 15.0, *)
struct TrendAnalysisView: View {
    let healthRecords: [HealthData]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Trend Analysis")
                .font(.title2)
                .fontWeight(.semibold)
            
            Chart(healthRecords) { record in
                LineMark(
                    x: .value("Time", record.timestamp),
                    y: .value("Heart Rate", record.heartRate)
                )
                .foregroundStyle(.red)
                
                LineMark(
                    x: .value("Time", record.timestamp),
                    y: .value("HRV", record.hrv ?? 0)
                )
                .foregroundStyle(.blue)
            }
            .frame(height: 300)
        }
        .padding()
        .background(Color(.windowBackgroundColor))
        .cornerRadius(12)
    }
}

@available(macOS 15.0, *)
struct CorrelationAnalysisView: View {
    let healthRecords: [HealthData]
    let sleepSessions: [SleepSession]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Correlation Analysis")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Sleep Quality vs Heart Rate Variability")
                .font(.caption)
                .foregroundColor(.secondary)
            
            // Implement correlation analysis chart
            CorrelationChart(
                healthRecords: healthRecords,
                sleepSessions: sleepSessions
            )
            .frame(height: 200)
        }
        .padding()
        .background(Color(.windowBackgroundColor))
        .cornerRadius(12)
    }
}

@available(macOS 15.0, *)
struct CorrelationChart: View {
    let healthRecords: [HealthData]
    let sleepSessions: [SleepSession]
    
    private var correlationData: [CorrelationPoint] {
        calculateCorrelationData()
    }
    
    var body: some View {
        Chart(correlationData) { point in
            PointMark(
                x: .value("Sleep Quality", point.sleepQuality),
                y: .value("HRV", point.hrv)
            )
            .foregroundStyle(point.color)
            .symbolSize(50)
        }
        .chartXAxis {
            AxisMarks(position: .bottom) {
                AxisGridLine()
                AxisTick()
                AxisValueLabel()
            }
        }
        .chartYAxis {
            AxisMarks(position: .leading) {
                AxisGridLine()
                AxisTick()
                AxisValueLabel()
            }
        }
        .chartOverlay { proxy in
            GeometryReader { geometry in
                Rectangle().fill(.clear).contentShape(Rectangle())
                    .gesture(DragGesture()
                        .onChanged { value in
                            let location = value.location
                            if let point = proxy.value(at: location) as? CorrelationPoint {
                                // Show tooltip with point details
                                showTooltip(for: point, at: location)
                            }
                        }
                    )
            }
        }
    }
    
    private func calculateCorrelationData() -> [CorrelationPoint] {
        var correlationPoints: [CorrelationPoint] = []
        
        // Group health records by date
        let healthByDate = Dictionary(grouping: healthRecords) { record in
            Calendar.current.startOfDay(for: record.timestamp)
        }
        
        // Group sleep sessions by date
        let sleepByDate = Dictionary(grouping: sleepSessions) { session in
            Calendar.current.startOfDay(for: session.startDate)
        }
        
        // Calculate correlation for each day
        for date in healthByDate.keys {
            guard let dayHealth = healthByDate[date],
                  let daySleep = sleepByDate[date] else { continue }
            
            // Calculate average HRV for the day
            let hrvRecords = dayHealth.filter { $0.type == "heartRateVariability" }
            let averageHRV = hrvRecords.isEmpty ? 0 : hrvRecords.map { $0.value }.reduce(0, +) / Double(hrvRecords.count)
            
            // Calculate sleep quality for the day
            let sleepQuality = calculateSleepQuality(daySleep)
            
            if averageHRV > 0 && sleepQuality > 0 {
                let point = CorrelationPoint(
                    date: date,
                    sleepQuality: sleepQuality,
                    hrv: averageHRV,
                    color: determinePointColor(sleepQuality: sleepQuality, hrv: averageHRV)
                )
                correlationPoints.append(point)
            }
        }
        
        return correlationPoints.sorted { $0.date < $1.date }
    }
    
    private func calculateSleepQuality(_ sessions: [SleepSession]) -> Double {
        guard !sessions.isEmpty else { return 0 }
        
        let totalQuality = sessions.reduce(0) { sum, session in
            sum + (session.sleepQuality ?? 0)
        }
        
        return totalQuality / Double(sessions.count)
    }
    
    private func determinePointColor(sleepQuality: Double, hrv: Double) -> Color {
        // Color coding based on both sleep quality and HRV
        if sleepQuality >= 0.8 && hrv >= 50 {
            return .green // Excellent
        } else if sleepQuality >= 0.6 && hrv >= 40 {
            return .blue // Good
        } else if sleepQuality >= 0.4 && hrv >= 30 {
            return .orange // Fair
        } else {
            return .red // Poor
        }
    }
    
    private func showTooltip(for point: CorrelationPoint, at location: CGPoint) {
        // Show tooltip with detailed information
        // This would be implemented with a custom tooltip view
    }
}

@available(macOS 15.0, *)
struct CorrelationPoint: Identifiable {
    let id = UUID()
    let date: Date
    let sleepQuality: Double
    let hrv: Double
    let color: Color
}

// MARK: - Export Functionality

@available(macOS 15.0, *)
struct ExportAnalyticsView: View {
    let healthRecords: [HealthData]
    @Environment(\.dismiss) private var dismiss
    @State private var isExporting = false
    @State private var exportProgress = 0.0
    @State private var exportMessage = ""
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Export Analytics")
                .font(.title)
            
            if isExporting {
                VStack(spacing: 12) {
                    ProgressView(value: exportProgress)
                        .progressViewStyle(LinearProgressViewStyle())
                    
                    Text(exportMessage)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            } else {
                VStack(alignment: .leading, spacing: 12) {
                    Button("Export as CSV") {
                        exportAsCSV()
                    }
                    .buttonStyle(.bordered)
                    
                    Button("Export as PDF Report") {
                        exportAsPDF()
                    }
                    .buttonStyle(.bordered)
                    
                    Button("Share with Health App") {
                        shareWithHealthApp()
                    }
                    .buttonStyle(.bordered)
                }
            }
            
            Button("Cancel") {
                dismiss()
            }
            .buttonStyle(.bordered)
            .disabled(isExporting)
        }
        .padding()
        .frame(width: 300, height: 200)
    }
    
    private func exportAsCSV() {
        // Implement CSV export
        isExporting = true
        exportMessage = "Preparing CSV export..."
        
        Task {
            do {
                let csvExporter = CSVExporter()
                let csvData = try await csvExporter.exportHealthData(healthRecords)
                
                await MainActor.run {
                    exportProgress = 0.5
                    exportMessage = "Saving CSV file..."
                }
                
                let fileURL = try await saveCSVFile(csvData)
                
                await MainActor.run {
                    exportProgress = 1.0
                    exportMessage = "Export completed!"
                    
                    // Show file in Finder
                    NSWorkspace.shared.selectFile(fileURL.path, inFileViewerRootedAtPath: "")
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                        dismiss()
                    }
                }
                
            } catch {
                await MainActor.run {
                    exportMessage = "Export failed: \(error.localizedDescription)"
                    isExporting = false
                }
            }
        }
    }
    
    private func exportAsPDF() {
        // Implement PDF export
        isExporting = true
        exportMessage = "Generating PDF report..."
        
        Task {
            do {
                let pdfExporter = PDFExporter()
                let pdfData = try await pdfExporter.generateHealthReport(healthRecords)
                
                await MainActor.run {
                    exportProgress = 0.5
                    exportMessage = "Saving PDF file..."
                }
                
                let fileURL = try await savePDFFile(pdfData)
                
                await MainActor.run {
                    exportProgress = 1.0
                    exportMessage = "Export completed!"
                    
                    // Show file in Finder
                    NSWorkspace.shared.selectFile(fileURL.path, inFileViewerRootedAtPath: "")
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                        dismiss()
                    }
                }
                
            } catch {
                await MainActor.run {
                    exportMessage = "Export failed: \(error.localizedDescription)"
                    isExporting = false
                }
            }
        }
    }
    
    private func shareWithHealthApp() {
        // Implement Health app sharing
        isExporting = true
        exportMessage = "Preparing data for Health app..."
        
        Task {
            do {
                let healthAppSharer = HealthAppSharer()
                let sharedData = try await healthAppSharer.prepareDataForSharing(healthRecords)
                
                await MainActor.run {
                    exportProgress = 0.5
                    exportMessage = "Sharing with Health app..."
                }
                
                try await healthAppSharer.shareWithHealthApp(sharedData)
                
                await MainActor.run {
                    exportProgress = 1.0
                    exportMessage = "Data shared successfully!"
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                        dismiss()
                    }
                }
                
            } catch {
                await MainActor.run {
                    exportMessage = "Sharing failed: \(error.localizedDescription)"
                    isExporting = false
                }
            }
        }
    }
    
    private func saveCSVFile(_ csvData: Data) async throws -> URL {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let fileName = "HealthAI_Analytics_\(Date().ISO8601String()).csv"
        let fileURL = documentsPath.appendingPathComponent(fileName)
        
        try csvData.write(to: fileURL)
        return fileURL
    }
    
    private func savePDFFile(_ pdfData: Data) async throws -> URL {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let fileName = "HealthAI_Report_\(Date().ISO8601String()).pdf"
        let fileURL = documentsPath.appendingPathComponent(fileName)
        
        try pdfData.write(to: fileURL)
        return fileURL
    }
}

// MARK: - Export Services

@available(macOS 15.0, *)
class CSVExporter {
    func exportHealthData(_ records: [HealthData]) async throws -> Data {
        var csvString = "Date,Type,Value,Unit,Source\n"
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        
        for record in records {
            let dateString = dateFormatter.string(from: record.timestamp)
            let row = "\(dateString),\(record.type),\(record.value),\(record.unit ?? ""),\(record.source)\n"
            csvString += row
        }
        
        return csvString.data(using: .utf8) ?? Data()
    }
}

@available(macOS 15.0, *)
class PDFExporter {
    func generateHealthReport(_ records: [HealthData]) async throws -> Data {
        // Create PDF report with comprehensive health analytics
        let pdfGenerator = PDFReportGenerator()
        
        // Generate report sections
        let summarySection = try await generateSummarySection(records)
        let trendsSection = try await generateTrendsSection(records)
        let insightsSection = try await generateInsightsSection(records)
        
        // Combine sections into PDF
        let pdfData = try await pdfGenerator.generateReport(
            title: "Health AI 2030 Analytics Report",
            sections: [summarySection, trendsSection, insightsSection],
            metadata: generateReportMetadata(records)
        )
        
        return pdfData
    }
    
    private func generateSummarySection(_ records: [HealthData]) async throws -> PDFSection {
        let summary = calculateSummaryStatistics(records)
        
        return PDFSection(
            title: "Executive Summary",
            content: [
                "Total Records: \(summary.totalRecords)",
                "Date Range: \(summary.dateRange)",
                "Data Sources: \(summary.dataSources.joined(separator: ", "))",
                "Key Metrics: \(summary.keyMetrics.joined(separator: ", "))"
            ]
        )
    }
    
    private func generateTrendsSection(_ records: [HealthData]) async throws -> PDFSection {
        let trends = analyzeTrends(records)
        
        return PDFSection(
            title: "Health Trends Analysis",
            content: trends.map { "\($0.metric): \($0.trend) (\($0.changePercentage)%)" }
        )
    }
    
    private func generateInsightsSection(_ records: [HealthData]) async throws -> PDFSection {
        let insights = generateInsights(records)
        
        return PDFSection(
            title: "Key Insights & Recommendations",
            content: insights
        )
    }
    
    private func calculateSummaryStatistics(_ records: [HealthData]) -> SummaryStatistics {
        let totalRecords = records.count
        let dateRange = calculateDateRange(records)
        let dataSources = Array(Set(records.map { $0.source }))
        let keyMetrics = Array(Set(records.map { $0.type }))
        
        return SummaryStatistics(
            totalRecords: totalRecords,
            dateRange: dateRange,
            dataSources: dataSources,
            keyMetrics: keyMetrics
        )
    }
    
    private func calculateDateRange(_ records: [HealthData]) -> String {
        guard let firstDate = records.map({ $0.timestamp }).min(),
              let lastDate = records.map({ $0.timestamp }).max() else {
            return "No data"
        }
        
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return "\(formatter.string(from: firstDate)) - \(formatter.string(from: lastDate))"
    }
    
    private func analyzeTrends(_ records: [HealthData]) -> [HealthTrend] {
        // Analyze trends for different health metrics
        var trends: [HealthTrend] = []
        
        let metrics = Set(records.map { $0.type })
        for metric in metrics {
            let metricRecords = records.filter { $0.type == metric }
            let trend = calculateTrend(for: metricRecords)
            trends.append(trend)
        }
        
        return trends
    }
    
    private func calculateTrend(for records: [HealthData]) -> HealthTrend {
        // Calculate trend for a specific metric
        let sortedRecords = records.sorted { $0.timestamp < $1.timestamp }
        
        guard sortedRecords.count >= 2 else {
            return HealthTrend(metric: records.first?.type ?? "Unknown", trend: "Insufficient data", changePercentage: 0)
        }
        
        let firstValue = sortedRecords.first!.value
        let lastValue = sortedRecords.last!.value
        let changePercentage = ((lastValue - firstValue) / firstValue) * 100
        
        let trend: String
        if changePercentage > 5 {
            trend = "Improving"
        } else if changePercentage < -5 {
            trend = "Declining"
        } else {
            trend = "Stable"
        }
        
        return HealthTrend(
            metric: records.first?.type ?? "Unknown",
            trend: trend,
            changePercentage: changePercentage
        )
    }
    
    private func generateInsights(_ records: [HealthData]) -> [String] {
        var insights: [String] = []
        
        // Generate insights based on data analysis
        let heartRateRecords = records.filter { $0.type == "heartRate" }
        if !heartRateRecords.isEmpty {
            let avgHeartRate = heartRateRecords.map { $0.value }.reduce(0, +) / Double(heartRateRecords.count)
            if avgHeartRate > 80 {
                insights.append("Average heart rate is elevated. Consider stress management techniques.")
            }
        }
        
        let sleepRecords = records.filter { $0.type == "sleepDuration" }
        if !sleepRecords.isEmpty {
            let avgSleep = sleepRecords.map { $0.value }.reduce(0, +) / Double(sleepRecords.count)
            if avgSleep < 7 {
                insights.append("Sleep duration is below recommended levels. Focus on sleep hygiene.")
            }
        }
        
        return insights
    }
    
    private func generateReportMetadata(_ records: [HealthData]) -> ReportMetadata {
        return ReportMetadata(
            generatedAt: Date(),
            dataPoints: records.count,
            dateRange: calculateDateRange(records),
            version: "1.0"
        )
    }
}

@available(macOS 15.0, *)
class HealthAppSharer {
    func prepareDataForSharing(_ records: [HealthData]) async throws -> [HealthAppData] {
        // Convert HealthAI data to Health app format
        var healthAppData: [HealthAppData] = []
        
        for record in records {
            let healthData = HealthAppData(
                type: mapToHealthAppType(record.type),
                value: record.value,
                unit: record.unit ?? "",
                date: record.timestamp,
                source: "HealthAI 2030"
            )
            healthAppData.append(healthData)
        }
        
        return healthAppData
    }
    
    func shareWithHealthApp(_ data: [HealthAppData]) async throws {
        // Share data with Apple Health app
        let healthStore = HKHealthStore()
        
        // Request authorization
        let typesToShare: Set<HKSampleType> = Set(data.compactMap { healthData in
            HKObjectType.quantityType(forIdentifier: mapToHealthKitIdentifier(healthData.type))
        })
        
        try await healthStore.requestAuthorization(toShare: typesToShare, read: [])
        
        // Save data to HealthKit
        for healthData in data {
            try await saveToHealthKit(healthData)
        }
    }
    
    private func mapToHealthAppType(_ type: String) -> String {
        // Map HealthAI types to Health app types
        switch type {
        case "heartRate": return "Heart Rate"
        case "sleepDuration": return "Sleep Analysis"
        case "steps": return "Steps"
        case "activeEnergy": return "Active Energy"
        default: return type
        }
    }
    
    private func mapToHealthKitIdentifier(_ type: String) -> HKQuantityTypeIdentifier {
        // Map to HealthKit identifiers
        switch type {
        case "Heart Rate": return .heartRate
        case "Steps": return .stepCount
        case "Active Energy": return .activeEnergyBurned
        default: return .heartRate // Default fallback
        }
    }
    
    private func saveToHealthKit(_ data: HealthAppData) async throws {
        let healthStore = HKHealthStore()
        
        guard let quantityType = HKObjectType.quantityType(forIdentifier: mapToHealthKitIdentifier(data.type)) else {
            throw HealthAppSharingError.invalidDataType
        }
        
        let unit = HKUnit(from: data.unit)
        let quantity = HKQuantity(unit: unit, doubleValue: data.value)
        let sample = HKQuantitySample(type: quantityType, quantity: quantity, start: data.date, end: data.date)
        
        try await healthStore.save(sample)
    }
}

// MARK: - Supporting Types

@available(macOS 15.0, *)
struct PDFSection {
    let title: String
    let content: [String]
}

@available(macOS 15.0, *)
struct SummaryStatistics {
    let totalRecords: Int
    let dateRange: String
    let dataSources: [String]
    let keyMetrics: [String]
}

@available(macOS 15.0, *)
struct HealthTrend {
    let metric: String
    let trend: String
    let changePercentage: Double
}

@available(macOS 15.0, *)
struct ReportMetadata {
    let generatedAt: Date
    let dataPoints: Int
    let dateRange: String
    let version: String
}

@available(macOS 15.0, *)
struct HealthAppData {
    let type: String
    let value: Double
    let unit: String
    let date: Date
    let source: String
}

@available(macOS 15.0, *)
enum HealthAppSharingError: Error {
    case invalidDataType
    case authorizationDenied
    case saveFailed
}

// MARK: - Mock Classes

@available(macOS 15.0, *)
class PDFReportGenerator {
    func generateReport(title: String, sections: [PDFSection], metadata: ReportMetadata) async throws -> Data {
        // Mock PDF generation
        return Data()
    }
}

// MARK: - Date Extension

extension Date {
    func ISO8601String() -> String {
        let formatter = ISO8601DateFormatter()
        return formatter.string(from: self)
    }
}

