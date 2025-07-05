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
            
            // TODO: Implement correlation analysis chart
            Text("Correlation analysis coming soon...")
                .foregroundColor(.secondary)
                .frame(height: 200)
        }
        .padding()
        .background(Color(.windowBackgroundColor))
        .cornerRadius(12)
    }
}

// MARK: - Supporting Views

@available(macOS 15.0, *)
struct ExportAnalyticsView: View {
    let healthRecords: [HealthData]
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Export Analytics")
                .font(.title)
            
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
            
            Button("Cancel") {
                dismiss()
            }
            .buttonStyle(.bordered)
        }
        .padding()
        .frame(width: 300, height: 200)
    }
    
    private func exportAsCSV() {
        // TODO: Implement CSV export
        dismiss()
    }
    
    private func exportAsPDF() {
        // TODO: Implement PDF export
        dismiss()
    }
    
    private func shareWithHealthApp() {
        // TODO: Implement Health app sharing
        dismiss()
    }
}

@available(macOS 15.0, *)
struct AnalyticsSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Analytics Settings")
                .font(.title)
            
            VStack(alignment: .leading, spacing: 12) {
                Toggle("Auto-refresh data", isOn: .constant(true))
                Toggle("Show predictions", isOn: .constant(true))
                Toggle("Enable notifications", isOn: .constant(true))
            }
            
            Button("Done") {
                dismiss()
            }
            .buttonStyle(.bordered)
        }
        .padding()
        .frame(width: 300, height: 200)
    }
}

// MARK: - Supporting Types

enum TimeRange: CaseIterable {
    case day, week, month, quarter, year
    
    var displayName: String {
        switch self {
        case .day: return "24 Hours"
        case .week: return "7 Days"
        case .month: return "30 Days"
        case .quarter: return "3 Months"
        case .year: return "1 Year"
        }
    }
    
    var startDate: Date {
        let calendar = Calendar.current
        let now = Date()
        
        switch self {
        case .day:
            return calendar.date(byAdding: .day, value: -1, to: now) ?? now
        case .week:
            return calendar.date(byAdding: .day, value: -7, to: now) ?? now
        case .month:
            return calendar.date(byAdding: .month, value: -1, to: now) ?? now
        case .quarter:
            return calendar.date(byAdding: .month, value: -3, to: now) ?? now
        case .year:
            return calendar.date(byAdding: .year, value: -1, to: now) ?? now
        }
    }
}

enum HealthMetric: CaseIterable {
    case heartRate, sleep, activity, respiratory, mental, nutrition
    
    var displayName: String {
        switch self {
        case .heartRate: return "Heart Rate"
        case .sleep: return "Sleep"
        case .activity: return "Activity"
        case .respiratory: return "Respiratory"
        case .mental: return "Mental Health"
        case .nutrition: return "Nutrition"
        }
    }
    
    var icon: String {
        switch self {
        case .heartRate: return "heart.fill"
        case .sleep: return "bed.double.fill"
        case .activity: return "figure.run"
        case .respiratory: return "lungs.fill"
        case .mental: return "brain.head.profile"
        case .nutrition: return "fork.knife"
        }
    }
    
    var color: Color {
        switch self {
        case .heartRate: return .red
        case .sleep: return .purple
        case .activity: return .green
        case .respiratory: return .blue
        case .mental: return .orange
        case .nutrition: return .brown
        }
    }
}
