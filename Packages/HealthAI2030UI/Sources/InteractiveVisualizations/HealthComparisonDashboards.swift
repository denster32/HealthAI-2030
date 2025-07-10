import SwiftUI
import Charts

// MARK: - Health Comparison Dashboards
/// Comprehensive health comparison dashboard components for data analysis and benchmarking
/// Provides interactive comparison views for health metrics, progress tracking, and benchmarking
public struct HealthComparisonDashboards {
    
    // MARK: - Health Metrics Comparison
    
    /// Interactive dashboard for comparing health metrics over time
    public struct HealthMetricsComparison: View {
        let metrics: [HealthMetric]
        let comparisonPeriod: ComparisonPeriod
        let selectedMetrics: Set<HealthMetricType>
        @State private var showingDetails: Bool = false
        @State private var selectedTimeRange: TimeRange = .month
        
        public init(
            metrics: [HealthMetric],
            comparisonPeriod: ComparisonPeriod = .currentVsPrevious,
            selectedMetrics: Set<HealthMetricType> = Set(HealthMetricType.allCases)
        ) {
            self.metrics = metrics
            self.comparisonPeriod = comparisonPeriod
            self.selectedMetrics = selectedMetrics
        }
        
        public var body: some View {
            VStack(spacing: 20) {
                // Dashboard Header
                HStack {
                    Text("Health Metrics Comparison")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Spacer()
                    
                    Button(action: { showingDetails.toggle() }) {
                        Image(systemName: "info.circle")
                            .foregroundColor(.blue)
                    }
                }
                .padding(.horizontal)
                
                // Time Range Selector
                Picker("Time Range", selection: $selectedTimeRange) {
                    ForEach(TimeRange.allCases, id: \.self) { range in
                        Text(range.displayName).tag(range)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(.horizontal)
                
                // Comparison Chart
                Chart {
                    ForEach(filteredMetrics, id: \.id) { metric in
                        LineMark(
                            x: .value("Date", metric.date),
                            y: .value("Value", metric.value)
                        )
                        .foregroundStyle(metric.type.color)
                        .symbol(Circle().strokeBorder(lineWidth: 2))
                    }
                }
                .frame(height: 200)
                .padding(.horizontal)
                
                // Metrics Summary
                MetricsSummaryView(metrics: filteredMetrics)
                    .padding(.horizontal)
                
                // Comparison Table
                ComparisonTableView(
                    metrics: filteredMetrics,
                    comparisonPeriod: comparisonPeriod
                )
                .padding(.horizontal)
            }
            .background(Color(.systemBackground))
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
            .sheet(isPresented: $showingDetails) {
                ComparisonDetailsView(metrics: metrics)
            }
        }
        
        private var filteredMetrics: [HealthMetric] {
            metrics.filter { metric in
                selectedMetrics.contains(metric.type) &&
                selectedTimeRange.contains(metric.date)
            }
        }
    }
    
    // MARK: - Benchmark Comparison
    
    /// Dashboard for comparing personal health data against benchmarks
    public struct BenchmarkComparison: View {
        let personalData: [HealthMetric]
        let benchmarks: [HealthBenchmark]
        let ageGroup: String
        let gender: String?
        @State private var selectedMetric: HealthMetricType = .heartRate
        @State private var showingBenchmarkDetails: Bool = false
        
        public init(
            personalData: [HealthMetric],
            benchmarks: [HealthBenchmark],
            ageGroup: String,
            gender: String? = nil
        ) {
            self.personalData = personalData
            self.benchmarks = benchmarks
            self.ageGroup = ageGroup
            self.gender = gender
        }
        
        public var body: some View {
            VStack(spacing: 20) {
                // Benchmark Header
                HStack {
                    Text("Benchmark Comparison")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Spacer()
                    
                    VStack(alignment: .trailing) {
                        Text("Age Group: \(ageGroup)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        if let gender = gender {
                            Text("Gender: \(gender)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding(.horizontal)
                
                // Metric Selector
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(HealthMetricType.allCases, id: \.self) { metricType in
                            MetricTypeButton(
                                metricType: metricType,
                                isSelected: selectedMetric == metricType,
                                action: { selectedMetric = metricType }
                            )
                        }
                    }
                    .padding(.horizontal)
                }
                
                // Benchmark Chart
                BenchmarkChartView(
                    personalData: personalDataForSelectedMetric,
                    benchmark: benchmarkForSelectedMetric,
                    metricType: selectedMetric
                )
                .frame(height: 250)
                .padding(.horizontal)
                
                // Benchmark Summary
                BenchmarkSummaryView(
                    personalData: personalDataForSelectedMetric,
                    benchmark: benchmarkForSelectedMetric,
                    metricType: selectedMetric
                )
                .padding(.horizontal)
            }
            .background(Color(.systemBackground))
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
        }
        
        private var personalDataForSelectedMetric: [HealthMetric] {
            personalData.filter { $0.type == selectedMetric }
        }
        
        private var benchmarkForSelectedMetric: HealthBenchmark? {
            benchmarks.first { $0.metricType == selectedMetric }
        }
    }
    
    // MARK: - Progress Comparison
    
    /// Dashboard for comparing progress across different health goals
    public struct ProgressComparison: View {
        let healthGoals: [HealthGoal]
        let progressData: [GoalProgress]
        @State private var selectedTimeframe: Timeframe = .month
        @State private var showingGoalDetails: Bool = false
        
        public init(
            healthGoals: [HealthGoal],
            progressData: [GoalProgress] = []
        ) {
            self.healthGoals = healthGoals
            self.progressData = progressData
        }
        
        public var body: some View {
            VStack(spacing: 20) {
                // Progress Header
                HStack {
                    Text("Goal Progress Comparison")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Spacer()
                    
                    Picker("Timeframe", selection: $selectedTimeframe) {
                        ForEach(Timeframe.allCases, id: \.self) { timeframe in
                            Text(timeframe.displayName).tag(timeframe)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .frame(width: 200)
                }
                .padding(.horizontal)
                
                // Progress Overview
                ProgressOverviewGrid(goals: healthGoals, progressData: progressData)
                    .padding(.horizontal)
                
                // Progress Chart
                ProgressComparisonChart(
                    goals: healthGoals,
                    progressData: progressDataForTimeframe
                )
                .frame(height: 200)
                .padding(.horizontal)
                
                // Goal Details
                GoalDetailsList(
                    goals: healthGoals,
                    progressData: progressDataForTimeframe
                )
                .padding(.horizontal)
            }
            .background(Color(.systemBackground))
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
        }
        
        private var progressDataForTimeframe: [GoalProgress] {
            progressData.filter { progress in
                selectedTimeframe.contains(progress.date)
            }
        }
    }
    
    // MARK: - Population Comparison
    
    /// Dashboard for comparing personal health data with population statistics
    public struct PopulationComparison: View {
        let personalData: [HealthMetric]
        let populationStats: [PopulationStatistic]
        let demographic: Demographic
        @State private var selectedMetric: HealthMetricType = .heartRate
        @State private var showingPopulationDetails: Bool = false
        
        public init(
            personalData: [HealthMetric],
            populationStats: [PopulationStatistic],
            demographic: Demographic
        ) {
            self.personalData = personalData
            self.populationStats = populationStats
            self.demographic = demographic
        }
        
        public var body: some View {
            VStack(spacing: 20) {
                // Population Header
                HStack {
                    Text("Population Comparison")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Spacer()
                    
                    VStack(alignment: .trailing) {
                        Text("Demographic: \(demographic.description)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.horizontal)
                
                // Metric Selector
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(HealthMetricType.allCases, id: \.self) { metricType in
                            MetricTypeButton(
                                metricType: metricType,
                                isSelected: selectedMetric == metricType,
                                action: { selectedMetric = metricType }
                            )
                        }
                    }
                    .padding(.horizontal)
                }
                
                // Population Chart
                PopulationChartView(
                    personalData: personalDataForSelectedMetric,
                    populationStats: populationStatsForSelectedMetric,
                    metricType: selectedMetric
                )
                .frame(height: 250)
                .padding(.horizontal)
                
                // Population Summary
                PopulationSummaryView(
                    personalData: personalDataForSelectedMetric,
                    populationStats: populationStatsForSelectedMetric,
                    metricType: selectedMetric
                )
                .padding(.horizontal)
            }
            .background(Color(.systemBackground))
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
        }
        
        private var personalDataForSelectedMetric: [HealthMetric] {
            personalData.filter { $0.type == selectedMetric }
        }
        
        private var populationStatsForSelectedMetric: PopulationStatistic? {
            populationStats.first { $0.metricType == selectedMetric }
        }
    }
}

// MARK: - Supporting Views

struct MetricsSummaryView: View {
    let metrics: [HealthMetric]
    
    var body: some View {
        VStack(spacing: 12) {
            Text("Metrics Summary")
                .font(.headline)
                .fontWeight(.semibold)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                ForEach(metricSummaries, id: \.type) { summary in
                    MetricSummaryCard(summary: summary)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private var metricSummaries: [MetricSummary] {
        let grouped = Dictionary(grouping: metrics) { $0.type }
        return grouped.map { type, metrics in
            let values = metrics.map { $0.value }
            return MetricSummary(
                type: type,
                average: values.reduce(0, +) / Double(values.count),
                min: values.min() ?? 0,
                max: values.max() ?? 0,
                trend: calculateTrend(values)
            )
        }
    }
    
    private func calculateTrend(_ values: [Double]) -> Trend {
        guard values.count >= 2 else { return .stable }
        let firstHalf = Array(values.prefix(values.count / 2))
        let secondHalf = Array(values.suffix(values.count / 2))
        let firstAvg = firstHalf.reduce(0, +) / Double(firstHalf.count)
        let secondAvg = secondHalf.reduce(0, +) / Double(secondHalf.count)
        
        if secondAvg > firstAvg * 1.1 {
            return .improving
        } else if secondAvg < firstAvg * 0.9 {
            return .declining
        } else {
            return .stable
        }
    }
}

struct MetricSummaryCard: View {
    let summary: MetricSummary
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(summary.type.displayName)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Spacer()
                
                Image(systemName: summary.trend.iconName)
                    .foregroundColor(summary.trend.color)
                    .font(.caption)
            }
            
            Text(String(format: "%.1f", summary.average))
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(summary.type.color)
            
            HStack {
                Text("Min: \(String(format: "%.1f", summary.min))")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text("Max: \(String(format: "%.1f", summary.max))")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(8)
    }
}

struct ComparisonTableView: View {
    let metrics: [HealthMetric]
    let comparisonPeriod: ComparisonPeriod
    
    var body: some View {
        VStack(spacing: 12) {
            Text("Comparison Table")
                .font(.headline)
                .fontWeight(.semibold)
            
            ScrollView {
                LazyVStack(spacing: 8) {
                    ForEach(comparisonData, id: \.type) { comparison in
                        ComparisonRowView(comparison: comparison)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private var comparisonData: [MetricComparison] {
        let grouped = Dictionary(grouping: metrics) { $0.type }
        return grouped.map { type, metrics in
            let currentPeriod = getCurrentPeriodMetrics(metrics)
            let previousPeriod = getPreviousPeriodMetrics(metrics)
            
            return MetricComparison(
                type: type,
                currentAverage: currentPeriod.reduce(0, +) / Double(currentPeriod.count),
                previousAverage: previousPeriod.reduce(0, +) / Double(previousPeriod.count),
                change: calculateChange(current: currentPeriod, previous: previousPeriod)
            )
        }
    }
    
    private func getCurrentPeriodMetrics(_ metrics: [HealthMetric]) -> [Double] {
        // Implementation depends on comparison period
        return metrics.map { $0.value }
    }
    
    private func getPreviousPeriodMetrics(_ metrics: [HealthMetric]) -> [Double] {
        // Implementation depends on comparison period
        return metrics.map { $0.value }
    }
    
    private func calculateChange(current: [Double], previous: [Double]) -> Double {
        guard !previous.isEmpty else { return 0 }
        let currentAvg = current.reduce(0, +) / Double(current.count)
        let previousAvg = previous.reduce(0, +) / Double(previous.count)
        return ((currentAvg - previousAvg) / previousAvg) * 100
    }
}

struct ComparisonRowView: View {
    let comparison: MetricComparison
    
    var body: some View {
        HStack {
            Text(comparison.type.displayName)
                .font(.subheadline)
                .fontWeight(.medium)
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text(String(format: "%.1f", comparison.currentAverage))
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                HStack(spacing: 4) {
                    Image(systemName: comparison.change >= 0 ? "arrow.up" : "arrow.down")
                        .foregroundColor(comparison.change >= 0 ? .green : .red)
                        .font(.caption)
                    
                    Text(String(format: "%.1f%%", abs(comparison.change)))
                        .font(.caption)
                        .foregroundColor(comparison.change >= 0 ? .green : .red)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(8)
    }
}

struct BenchmarkChartView: View {
    let personalData: [HealthMetric]
    let benchmark: HealthBenchmark?
    let metricType: HealthMetricType
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("\(metricType.displayName) vs Benchmark")
                .font(.headline)
                .fontWeight(.semibold)
            
            if let benchmark = benchmark {
                Chart {
                    // Personal data line
                    ForEach(personalData, id: \.id) { metric in
                        LineMark(
                            x: .value("Date", metric.date),
                            y: .value("Value", metric.value)
                        )
                        .foregroundStyle(metricType.color)
                        .symbol(Circle().strokeBorder(lineWidth: 2))
                    }
                    
                    // Benchmark lines
                    RuleMark(y: .value("Optimal", benchmark.optimal))
                        .foregroundStyle(.green)
                        .lineStyle(StrokeStyle(lineWidth: 2, dash: [5, 5]))
                    
                    RuleMark(y: .value("Average", benchmark.average))
                        .foregroundStyle(.orange)
                        .lineStyle(StrokeStyle(lineWidth: 2, dash: [5, 5]))
                    
                    RuleMark(y: .value("Minimum", benchmark.minimum))
                        .foregroundStyle(.red)
                        .lineStyle(StrokeStyle(lineWidth: 2, dash: [5, 5]))
                }
                
                // Legend
                HStack(spacing: 16) {
                    LegendItem(color: metricType.color, label: "Your Data")
                    LegendItem(color: .green, label: "Optimal")
                    LegendItem(color: .orange, label: "Average")
                    LegendItem(color: .red, label: "Minimum")
                }
                .font(.caption)
            } else {
                Text("No benchmark data available")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct LegendItem: View {
    let color: Color
    let label: String
    
    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            
            Text(label)
                .foregroundColor(.secondary)
        }
    }
}

struct BenchmarkSummaryView: View {
    let personalData: [HealthMetric]
    let benchmark: HealthBenchmark?
    let metricType: HealthMetricType
    
    var body: some View {
        VStack(spacing: 12) {
            Text("Benchmark Summary")
                .font(.headline)
                .fontWeight(.semibold)
            
            if let benchmark = benchmark, let personalAvg = personalAverage {
                HStack(spacing: 20) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Your Average")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(String(format: "%.1f", personalAvg))
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(metricType.color)
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Population Average")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(String(format: "%.1f", benchmark.average))
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.orange)
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Status")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(statusText)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(statusColor)
                    }
                }
            } else {
                Text("No benchmark data available")
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private var personalAverage: Double? {
        guard !personalData.isEmpty else { return nil }
        return personalData.map { $0.value }.reduce(0, +) / Double(personalData.count)
    }
    
    private var statusText: String {
        guard let personalAvg = personalAverage, let benchmark = benchmark else { return "Unknown" }
        
        if personalAvg >= benchmark.optimal {
            return "Excellent"
        } else if personalAvg >= benchmark.average {
            return "Good"
        } else if personalAvg >= benchmark.minimum {
            return "Fair"
        } else {
            return "Needs Improvement"
        }
    }
    
    private var statusColor: Color {
        guard let personalAvg = personalAverage, let benchmark = benchmark else { return .gray }
        
        if personalAvg >= benchmark.optimal {
            return .green
        } else if personalAvg >= benchmark.average {
            return .orange
        } else if personalAvg >= benchmark.minimum {
            return .yellow
        } else {
            return .red
        }
    }
}

struct ProgressOverviewGrid: View {
    let goals: [HealthGoal]
    let progressData: [GoalProgress]
    
    var body: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
            ForEach(goals) { goal in
                GoalProgressCard(
                    goal: goal,
                    progress: progressForGoal(goal)
                )
            }
        }
    }
    
    private func progressForGoal(_ goal: HealthGoal) -> Double {
        let goalProgress = progressData.filter { $0.goalId == goal.id }
        guard !goalProgress.isEmpty else { return 0 }
        return goalProgress.map { $0.progressPercentage }.reduce(0, +) / Double(goalProgress.count)
    }
}

struct GoalProgressCard: View {
    let goal: HealthGoal
    let progress: Double
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(goal.title)
                .font(.subheadline)
                .fontWeight(.medium)
                .lineLimit(2)
            
            ProgressView(value: progress)
                .progressViewStyle(LinearProgressViewStyle(tint: goal.category.color))
            
            HStack {
                Text("\(Int(progress * 100))%")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(goal.category.color)
                
                Spacer()
                
                Text(goal.targetValue)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }
}

struct ProgressComparisonChart: View {
    let goals: [HealthGoal]
    let progressData: [GoalProgress]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Progress Comparison")
                .font(.headline)
                .fontWeight(.semibold)
            
            Chart {
                ForEach(goals) { goal in
                    let goalProgress = progressData.filter { $0.goalId == goal.id }
                    if !goalProgress.isEmpty {
                        LineMark(
                            x: .value("Date", goalProgress.first?.date ?? Date()),
                            y: .value("Progress", goalProgress.map { $0.progressPercentage }.reduce(0, +) / Double(goalProgress.count))
                        )
                        .foregroundStyle(goal.category.color)
                        .symbol(Circle().strokeBorder(lineWidth: 2))
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct GoalDetailsList: View {
    let goals: [HealthGoal]
    let progressData: [GoalProgress]
    
    var body: some View {
        VStack(spacing: 12) {
            Text("Goal Details")
                .font(.headline)
                .fontWeight(.semibold)
            
            ForEach(goals) { goal in
                GoalDetailRow(
                    goal: goal,
                    progress: progressData.filter { $0.goalId == goal.id }
                )
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct GoalDetailRow: View {
    let goal: HealthGoal
    let progress: [GoalProgress]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(goal.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Spacer()
                
                Text(goal.category.displayName)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(goal.category.color.opacity(0.2))
                    .foregroundColor(goal.category.color)
                    .cornerRadius(8)
            }
            
            Text(goal.description)
                .font(.caption)
                .foregroundColor(.secondary)
                .lineLimit(2)
            
            if !progress.isEmpty {
                HStack {
                    Text("Progress: \(Int(averageProgress * 100))%")
                        .font(.caption)
                        .fontWeight(.medium)
                    
                    Spacer()
                    
                    Text("Last updated: \(progress.last?.date.formatted(date: .abbreviated, time: .omitted) ?? "Unknown")")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(8)
    }
    
    private var averageProgress: Double {
        guard !progress.isEmpty else { return 0 }
        return progress.map { $0.progressPercentage }.reduce(0, +) / Double(progress.count)
    }
}

struct PopulationChartView: View {
    let personalData: [HealthMetric]
    let populationStats: PopulationStatistic?
    let metricType: HealthMetricType
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("\(metricType.displayName) vs Population")
                .font(.headline)
                .fontWeight(.semibold)
            
            if let populationStats = populationStats {
                Chart {
                    // Personal data
                    ForEach(personalData, id: \.id) { metric in
                        PointMark(
                            x: .value("Date", metric.date),
                            y: .value("Value", metric.value)
                        )
                        .foregroundStyle(metricType.color)
                        .symbolSize(100)
                    }
                    
                    // Population distribution
                    RectangleMark(
                        x: .value("Range", "Population"),
                        yStart: .value("Min", populationStats.percentile25),
                        yEnd: .value("Max", populationStats.percentile75)
                    )
                    .foregroundStyle(.blue.opacity(0.3))
                    
                    RuleMark(y: .value("Median", populationStats.median))
                        .foregroundStyle(.blue)
                        .lineStyle(StrokeStyle(lineWidth: 2))
                }
                
                // Legend
                HStack(spacing: 16) {
                    LegendItem(color: metricType.color, label: "Your Data")
                    LegendItem(color: .blue, label: "Population Range")
                    LegendItem(color: .blue, label: "Population Median")
                }
                .font(.caption)
            } else {
                Text("No population data available")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct PopulationSummaryView: View {
    let personalData: [HealthMetric]
    let populationStats: PopulationStatistic?
    let metricType: HealthMetricType
    
    var body: some View {
        VStack(spacing: 12) {
            Text("Population Summary")
                .font(.headline)
                .fontWeight(.semibold)
            
            if let populationStats = populationStats, let personalAvg = personalAverage {
                HStack(spacing: 20) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Your Average")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(String(format: "%.1f", personalAvg))
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(metricType.color)
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Population Median")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(String(format: "%.1f", populationStats.median))
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.blue)
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Percentile")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(percentileText)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(percentileColor)
                    }
                }
            } else {
                Text("No population data available")
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private var personalAverage: Double? {
        guard !personalData.isEmpty else { return nil }
        return personalData.map { $0.value }.reduce(0, +) / Double(personalData.count)
    }
    
    private var percentileText: String {
        guard let personalAvg = personalAverage, let populationStats = populationStats else { return "Unknown" }
        
        if personalAvg <= populationStats.percentile10 {
            return "10th"
        } else if personalAvg <= populationStats.percentile25 {
            return "25th"
        } else if personalAvg <= populationStats.median {
            return "50th"
        } else if personalAvg <= populationStats.percentile75 {
            return "75th"
        } else if personalAvg <= populationStats.percentile90 {
            return "90th"
        } else {
            return "95th+"
        }
    }
    
    private var percentileColor: Color {
        guard let personalAvg = personalAverage, let populationStats = populationStats else { return .gray }
        
        if personalAvg <= populationStats.percentile10 {
            return .red
        } else if personalAvg <= populationStats.percentile25 {
            return .orange
        } else if personalAvg <= populationStats.median {
            return .yellow
        } else if personalAvg <= populationStats.percentile75 {
            return .green
        } else {
            return .blue
        }
    }
}

// MARK: - Supporting Views

struct MetricTypeButton: View {
    let metricType: HealthMetricType
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(metricType.displayName)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(isSelected ? .white : .primary)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isSelected ? metricType.color : Color(.systemGray5))
                .cornerRadius(16)
        }
    }
}

struct ComparisonDetailsView: View {
    let metrics: [HealthMetric]
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Comparison Details")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("This dashboard shows detailed comparison of your health metrics over time, including trends, patterns, and statistical analysis.")
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .padding()
                
                Spacer()
            }
            .padding()
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Data Models

struct HealthMetric: Identifiable {
    let id = UUID()
    let type: HealthMetricType
    let value: Double
    let date: Date
    let unit: String
    let notes: String?
}

enum HealthMetricType: CaseIterable {
    case heartRate
    case bloodPressure
    case temperature
    case weight
    case steps
    case sleepHours
    case calories
    case waterIntake
    case bloodSugar
    case oxygenSaturation
    
    var displayName: String {
        switch self {
        case .heartRate: return "Heart Rate"
        case .bloodPressure: return "Blood Pressure"
        case .temperature: return "Temperature"
        case .weight: return "Weight"
        case .steps: return "Steps"
        case .sleepHours: return "Sleep Hours"
        case .calories: return "Calories"
        case .waterIntake: return "Water Intake"
        case .bloodSugar: return "Blood Sugar"
        case .oxygenSaturation: return "Oxygen Saturation"
        }
    }
    
    var color: Color {
        switch self {
        case .heartRate: return .red
        case .bloodPressure: return .orange
        case .temperature: return .yellow
        case .weight: return .green
        case .steps: return .blue
        case .sleepHours: return .indigo
        case .calories: return .purple
        case .waterIntake: return .cyan
        case .bloodSugar: return .pink
        case .oxygenSaturation: return .mint
        }
    }
}

enum ComparisonPeriod: CaseIterable {
    case currentVsPrevious
    case weekOverWeek
    case monthOverMonth
    case yearOverYear
}

enum Timeframe: CaseIterable {
    case week
    case month
    case quarter
    case year
    
    var displayName: String {
        switch self {
        case .week: return "Week"
        case .month: return "Month"
        case .quarter: return "Quarter"
        case .year: return "Year"
        }
    }
    
    func contains(_ date: Date) -> Bool {
        let calendar = Calendar.current
        let now = Date()
        
        switch self {
        case .week:
            return calendar.isDate(date, equalTo: now, toGranularity: .weekOfYear)
        case .month:
            return calendar.isDate(date, equalTo: now, toGranularity: .month)
        case .quarter:
            let quarter = (calendar.component(.month, from: now) - 1) / 3
            let eventQuarter = (calendar.component(.month, from: date) - 1) / 3
            return quarter == eventQuarter && calendar.isDate(date, equalTo: now, toGranularity: .year)
        case .year:
            return calendar.isDate(date, equalTo: now, toGranularity: .year)
        }
    }
}

struct MetricSummary {
    let type: HealthMetricType
    let average: Double
    let min: Double
    let max: Double
    let trend: Trend
}

enum Trend {
    case improving
    case declining
    case stable
    
    var iconName: String {
        switch self {
        case .improving: return "arrow.up"
        case .declining: return "arrow.down"
        case .stable: return "arrow.right"
        }
    }
    
    var color: Color {
        switch self {
        case .improving: return .green
        case .declining: return .red
        case .stable: return .gray
        }
    }
}

struct MetricComparison {
    let type: HealthMetricType
    let currentAverage: Double
    let previousAverage: Double
    let change: Double
}

struct HealthBenchmark {
    let metricType: HealthMetricType
    let optimal: Double
    let average: Double
    let minimum: Double
    let ageGroup: String
    let gender: String?
}

struct HealthGoal: Identifiable {
    let id = UUID()
    let title: String
    let description: String
    let category: GoalCategory
    let targetValue: String
    let startDate: Date
    let endDate: Date?
}

enum GoalCategory: CaseIterable {
    case fitness
    case nutrition
    case sleep
    case mental
    case medical
    
    var displayName: String {
        switch self {
        case .fitness: return "Fitness"
        case .nutrition: return "Nutrition"
        case .sleep: return "Sleep"
        case .mental: return "Mental Health"
        case .medical: return "Medical"
        }
    }
    
    var color: Color {
        switch self {
        case .fitness: return .green
        case .nutrition: return .orange
        case .sleep: return .indigo
        case .mental: return .purple
        case .medical: return .red
        }
    }
}

struct GoalProgress: Identifiable {
    let id = UUID()
    let goalId: UUID
    let date: Date
    let progressPercentage: Double
    let notes: String?
}

struct PopulationStatistic {
    let metricType: HealthMetricType
    let median: Double
    let percentile10: Double
    let percentile25: Double
    let percentile75: Double
    let percentile90: Double
    let demographic: Demographic
}

struct Demographic {
    let ageGroup: String
    let gender: String?
    let region: String?
    
    var description: String {
        var desc = ageGroup
        if let gender = gender {
            desc += ", \(gender)"
        }
        if let region = region {
            desc += ", \(region)"
        }
        return desc
    }
} 