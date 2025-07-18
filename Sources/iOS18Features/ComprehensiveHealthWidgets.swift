import SwiftUI
import WidgetKit

// MARK: - Comprehensive Health Widget Bundle

@available(iOS 18.0, *)
struct HealthWidgetBundle: WidgetBundle {
    var body: some Widget {
        // Primary health widgets
        HealthDashboardWidget()
        HeartRateWidget()
        ActivityWidget()
        SleepWidget()
        WaterIntakeWidget()
        HealthScoreWidget()
        WorkoutWidget()
        MedicationWidget()
        
        // Smart widgets
        HealthSuggestionWidget()
        FocusModeHealthWidget()
        
        // Live Activities
        AdvancedHealthLiveActivity()
    }
}

// MARK: - Health Dashboard Widget (Primary Widget)

@available(iOS 18.0, *)
struct HealthDashboardWidget: Widget {
    let kind: String = "HealthDashboardWidget"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: HealthDashboardProvider()) { entry in
            HealthDashboardWidgetView(entry: entry)
        }
        .configurationDisplayName("Health Dashboard")
        .description("Your complete health overview at a glance")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge, .systemExtraLarge])
    }
}

@available(iOS 18.0, *)
struct HealthDashboardProvider: TimelineProvider {
    func placeholder(in context: Context) -> HealthDashboardEntry {
        HealthDashboardEntry(
            date: Date(),
            healthData: HealthDashboardData(
                heartRate: 72,
                steps: 8750,
                stepGoal: 10000,
                waterIntake: 48,
                waterGoal: 64,
                sleepHours: 7.5,
                sleepGoal: 8.0,
                caloriesBurned: 420,
                healthScore: 85,
                activeWorkout: nil,
                todayTrend: .improving
            )
        )
    }
    
    func getSnapshot(in context: Context, completion: @escaping (HealthDashboardEntry) -> ()) {
        let entry = HealthDashboardEntry(
            date: Date(),
            healthData: HealthDashboardData(
                heartRate: 68,
                steps: 6200,
                stepGoal: 10000,
                waterIntake: 32,
                waterGoal: 64,
                sleepHours: 8.2,
                sleepGoal: 8.0,
                caloriesBurned: 280,
                healthScore: 78,
                activeWorkout: WorkoutSession(type: .walking, startTime: Date(), estimatedDuration: nil),
                todayTrend: .stable
            )
        )
        completion(entry)
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<HealthDashboardEntry>) -> ()) {
        Task {
            let entry = await getCurrentHealthDashboardEntry()
            let timeline = Timeline(entries: [entry], policy: .after(Date().addingTimeInterval(900))) // 15 minutes
            completion(timeline)
        }
    }
    
    private func getCurrentHealthDashboardEntry() async -> HealthDashboardEntry {
        let healthManager = HealthDataManager.shared
        
        let heartRate = await healthManager.getLatestHeartRate()
        let steps = await healthManager.getTodaySteps()
        let water = await healthManager.getTodayWaterIntake()
        let sleep = await healthManager.getLastNightSleep()
        let healthScore = await healthManager.calculateHealthScore()
        
        let healthData = HealthDashboardData(
            heartRate: Int(heartRate ?? 0),
            steps: Int(steps ?? 0),
            stepGoal: 10000,
            waterIntake: Int(water),
            waterGoal: 64,
            sleepHours: sleep?.duration ?? 0 / 3600,
            sleepGoal: 8.0,
            caloriesBurned: Int.random(in: 200...600),
            healthScore: Int(healthScore),
            activeWorkout: nil, // Would check for active workout
            todayTrend: .stable // Would calculate actual trend
        )
        
        return HealthDashboardEntry(date: Date(), healthData: healthData)
    }
}

@available(iOS 18.0, *)
struct HealthDashboardEntry: TimelineEntry {
    let date: Date
    let healthData: HealthDashboardData
}

@available(iOS 18.0, *)
struct HealthDashboardData {
    let heartRate: Int
    let steps: Int
    let stepGoal: Int
    let waterIntake: Int
    let waterGoal: Int
    let sleepHours: Double
    let sleepGoal: Double
    let caloriesBurned: Int
    let healthScore: Int
    let activeWorkout: WorkoutSession?
    let todayTrend: HealthTrend
}

@available(iOS 18.0, *)
enum HealthTrend {
    case improving
    case stable
    case declining
    
    var color: Color {
        switch self {
        case .improving: return .green
        case .stable: return .blue
        case .declining: return .orange
        }
    }
    
    var icon: String {
        switch self {
        case .improving: return "arrow.up.circle.fill"
        case .stable: return "minus.circle.fill"
        case .declining: return "arrow.down.circle.fill"
        }
    }
}

@available(iOS 18.0, *)
struct HealthDashboardWidgetView: View {
    var entry: HealthDashboardProvider.Entry
    @Environment(\.widgetFamily) var family
    
    var body: some View {
        switch family {
        case .systemSmall:
            SmallHealthDashboardView(entry: entry)
        case .systemMedium:
            MediumHealthDashboardView(entry: entry)
        case .systemLarge:
            LargeHealthDashboardView(entry: entry)
        case .systemExtraLarge:
            ExtraLargeHealthDashboardView(entry: entry)
        default:
            SmallHealthDashboardView(entry: entry)
        }
    }
}

// MARK: - Small Health Dashboard View

@available(iOS 18.0, *)
struct SmallHealthDashboardView: View {
    let entry: HealthDashboardEntry
    
    var body: some View {
        VStack(spacing: 8) {
            // Header
            HStack {
                Text("Health")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.blue)
                
                Spacer()
                
                Image(systemName: entry.healthData.todayTrend.icon)
                    .font(.caption)
                    .foregroundColor(entry.healthData.todayTrend.color)
            }
            
            // Health Score (Primary metric)
            VStack(spacing: 4) {
                Text("\(entry.healthData.healthScore)")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Text("Health Score")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            // Quick metrics
            HStack(spacing: 8) {
                QuickMetric(
                    icon: "heart.fill",
                    value: "\(entry.healthData.heartRate)",
                    color: .red
                )
                
                QuickMetric(
                    icon: "figure.walk",
                    value: "\(entry.healthData.steps / 1000)K",
                    color: .blue
                )
                
                QuickMetric(
                    icon: "drop.fill",
                    value: "\(entry.healthData.waterIntake)",
                    color: .cyan
                )
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - Medium Health Dashboard View

@available(iOS 18.0, *)
struct MediumHealthDashboardView: View {
    let entry: HealthDashboardEntry
    
    var body: some View {
        VStack(spacing: 12) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Health Dashboard")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Text(entry.date, style: .time)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Health Score with trend
                VStack(alignment: .trailing, spacing: 2) {
                    HStack(spacing: 4) {
                        Text("\(entry.healthData.healthScore)")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                        
                        Image(systemName: entry.healthData.todayTrend.icon)
                            .font(.caption)
                            .foregroundColor(entry.healthData.todayTrend.color)
                    }
                    
                    Text("Health Score")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            
            // Main metrics grid
            HStack(spacing: 16) {
                // Steps with progress
                VStack(spacing: 4) {
                    CircularProgress(
                        progress: Double(entry.healthData.steps) / Double(entry.healthData.stepGoal),
                        color: .blue,
                        size: 50
                    ) {
                        VStack(spacing: 1) {
                            Text("\(entry.healthData.steps / 1000)K")
                                .font(.caption)
                                .fontWeight(.semibold)
                            Text("steps")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Text("\(Int((Double(entry.healthData.steps) / Double(entry.healthData.stepGoal)) * 100))%")
                        .font(.caption2)
                        .foregroundColor(.blue)
                }
                
                // Water with progress
                VStack(spacing: 4) {
                    CircularProgress(
                        progress: Double(entry.healthData.waterIntake) / Double(entry.healthData.waterGoal),
                        color: .cyan,
                        size: 50
                    ) {
                        VStack(spacing: 1) {
                            Text("\(entry.healthData.waterIntake)")
                                .font(.caption)
                                .fontWeight(.semibold)
                            Text("oz")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Text("\(Int((Double(entry.healthData.waterIntake) / Double(entry.healthData.waterGoal)) * 100))%")
                        .font(.caption2)
                        .foregroundColor(.cyan)
                }
                
                // Additional metrics
                VStack(spacing: 8) {
                    MetricRow(
                        icon: "heart.fill",
                        value: "\(entry.healthData.heartRate)",
                        unit: "BPM",
                        color: .red
                    )
                    
                    MetricRow(
                        icon: "moon.zzz",
                        value: String(format: "%.1f", entry.healthData.sleepHours),
                        unit: "hrs",
                        color: .indigo
                    )
                    
                    MetricRow(
                        icon: "flame.fill",
                        value: "\(entry.healthData.caloriesBurned)",
                        unit: "cal",
                        color: .orange
                    )
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - Large Health Dashboard View

@available(iOS 18.0, *)
struct LargeHealthDashboardView: View {
    let entry: HealthDashboardEntry
    
    var body: some View {
        VStack(spacing: 16) {
            // Header with comprehensive info
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Health Dashboard")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    HStack(spacing: 8) {
                        Text(entry.date, style: .date)
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        if let workout = entry.healthData.activeWorkout {
                            HStack(spacing: 4) {
                                Circle()
                                    .fill(.green)
                                    .frame(width: 6, height: 6)
                                Text("Active Workout")
                                    .font(.caption)
                                    .foregroundColor(.green)
                            }
                        }
                    }
                }
                
                Spacer()
                
                // Health Score with detailed trend
                VStack(alignment: .trailing, spacing: 4) {
                    HStack(spacing: 6) {
                        Text("\(entry.healthData.healthScore)")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                        
                        VStack(spacing: 2) {
                            Image(systemName: entry.healthData.todayTrend.icon)
                                .font(.title3)
                                .foregroundColor(entry.healthData.todayTrend.color)
                            
                            Text("Today")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Text("Health Score")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            // Primary metrics with progress rings
            HStack(spacing: 20) {
                // Steps
                ProgressRingMetric(
                    title: "Steps",
                    value: entry.healthData.steps,
                    goal: entry.healthData.stepGoal,
                    unit: "steps",
                    color: .blue,
                    ringSize: 80
                )
                
                // Water
                ProgressRingMetric(
                    title: "Water",
                    value: entry.healthData.waterIntake,
                    goal: entry.healthData.waterGoal,
                    unit: "oz",
                    color: .cyan,
                    ringSize: 80
                )
                
                // Sleep
                ProgressRingMetric(
                    title: "Sleep",
                    value: Int(entry.healthData.sleepHours * 10),
                    goal: Int(entry.healthData.sleepGoal * 10),
                    unit: "hrs",
                    color: .indigo,
                    ringSize: 80
                )
            }
            
            // Secondary metrics grid
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 12) {
                SecondaryMetricCard(
                    icon: "heart.fill",
                    title: "Heart Rate",
                    value: "\(entry.healthData.heartRate)",
                    unit: "BPM",
                    color: .red
                )
                
                SecondaryMetricCard(
                    icon: "flame.fill",
                    title: "Calories",
                    value: "\(entry.healthData.caloriesBurned)",
                    unit: "cal",
                    color: .orange
                )
                
                SecondaryMetricCard(
                    icon: "brain.head.profile",
                    title: "Mindfulness",
                    value: "12",
                    unit: "min",
                    color: .purple
                )
                
                SecondaryMetricCard(
                    icon: "chart.line.uptrend.xyaxis",
                    title: "Weekly Avg",
                    value: "\(entry.healthData.healthScore - 3)",
                    unit: "score",
                    color: .green
                )
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - Extra Large Health Dashboard View

@available(iOS 18.0, *)
struct ExtraLargeHealthDashboardView: View {
    let entry: HealthDashboardEntry
    
    var body: some View {
        VStack(spacing: 20) {
            // Comprehensive header
            HStack {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Health Dashboard")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    HStack(spacing: 12) {
                        Text(entry.date, style: .date)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        if let workout = entry.healthData.activeWorkout {
                            HStack(spacing: 6) {
                                Circle()
                                    .fill(.green)
                                    .frame(width: 8, height: 8)
                                Text("Workout Active")
                                    .font(.subheadline)
                                    .foregroundColor(.green)
                            }
                        }
                        
                        HStack(spacing: 4) {
                            Image(systemName: entry.healthData.todayTrend.icon)
                                .font(.subheadline)
                                .foregroundColor(entry.healthData.todayTrend.color)
                            Text("Trending \(trendText(entry.healthData.todayTrend))")
                                .font(.subheadline)
                                .foregroundColor(entry.healthData.todayTrend.color)
                        }
                    }
                }
                
                Spacer()
                
                // Large health score display
                VStack(spacing: 8) {
                    Text("\(entry.healthData.healthScore)")
                        .font(.system(size: 48, weight: .bold))
                        .foregroundColor(.primary)
                    
                    Text("Overall Health Score")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    HealthScoreIndicator(score: entry.healthData.healthScore)
                }
            }
            
            // Large progress rings section
            HStack(spacing: 30) {
                LargeProgressRingMetric(
                    title: "Daily Steps",
                    value: entry.healthData.steps,
                    goal: entry.healthData.stepGoal,
                    unit: "steps",
                    color: .blue,
                    ringSize: 120
                )
                
                LargeProgressRingMetric(
                    title: "Hydration",
                    value: entry.healthData.waterIntake,
                    goal: entry.healthData.waterGoal,
                    unit: "ounces",
                    color: .cyan,
                    ringSize: 120
                )
                
                LargeProgressRingMetric(
                    title: "Sleep Quality",
                    value: Int(entry.healthData.sleepHours * 10),
                    goal: Int(entry.healthData.sleepGoal * 10),
                    unit: "hours",
                    color: .indigo,
                    ringSize: 120
                )
            }
            
            // Comprehensive metrics grid
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 16) {
                DetailedMetricCard(
                    icon: "heart.fill",
                    title: "Heart Rate",
                    value: "\(entry.healthData.heartRate)",
                    unit: "BPM",
                    subtitle: "Resting",
                    color: .red
                )
                
                DetailedMetricCard(
                    icon: "flame.fill",
                    title: "Active Calories",
                    value: "\(entry.healthData.caloriesBurned)",
                    unit: "cal",
                    subtitle: "Burned",
                    color: .orange
                )
                
                DetailedMetricCard(
                    icon: "brain.head.profile",
                    title: "Mindfulness",
                    value: "15",
                    unit: "min",
                    subtitle: "Today",
                    color: .purple
                )
                
                DetailedMetricCard(
                    icon: "moon.zzz",
                    title: "Sleep Score",
                    value: "92",
                    unit: "%",
                    subtitle: "Efficiency",
                    color: .indigo
                )
                
                DetailedMetricCard(
                    icon: "chart.line.uptrend.xyaxis",
                    title: "Week Trend",
                    value: "+5",
                    unit: "pts",
                    subtitle: "Improving",
                    color: .green
                )
                
                DetailedMetricCard(
                    icon: "target",
                    title: "Goals Met",
                    value: "3",
                    unit: "/5",
                    subtitle: "Today",
                    color: .blue
                )
            }
        }
        .padding(20)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    private func trendText(_ trend: HealthTrend) -> String {
        switch trend {
        case .improving: return "Up"
        case .stable: return "Stable"
        case .declining: return "Down"
        }
    }
}

// MARK: - Supporting Views

@available(iOS 18.0, *)
struct QuickMetric: View {
    let icon: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 2) {
            Image(systemName: icon)
                .font(.caption2)
                .foregroundColor(color)
            Text(value)
                .font(.caption2)
                .fontWeight(.medium)
        }
    }
}

@available(iOS 18.0, *)
struct CircularProgress<Content: View>: View {
    let progress: Double
    let color: Color
    let size: CGFloat
    let content: () -> Content
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(color.opacity(0.2), lineWidth: 4)
                .frame(width: size, height: size)
            
            Circle()
                .trim(from: 0, to: CGFloat(min(progress, 1.0)))
                .stroke(color, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                .frame(width: size, height: size)
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 1.0), value: progress)
            
            content()
        }
    }
}

@available(iOS 18.0, *)
struct MetricRow: View {
    let icon: String
    let value: String
    let unit: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(color)
                .frame(width: 12)
            
            Text(value)
                .font(.caption)
                .fontWeight(.semibold)
            
            Text(unit)
                .font(.caption2)
                .foregroundColor(.secondary)
            
            Spacer()
        }
    }
}

@available(iOS 18.0, *)
struct ProgressRingMetric: View {
    let title: String
    let value: Int
    let goal: Int
    let unit: String
    let color: Color
    let ringSize: CGFloat
    
    var body: some View {
        VStack(spacing: 8) {
            CircularProgress(
                progress: Double(value) / Double(goal),
                color: color,
                size: ringSize
            ) {
                VStack(spacing: 2) {
                    Text("\(value)")
                        .font(.headline)
                        .fontWeight(.bold)
                    Text(unit)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            
            VStack(spacing: 2) {
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
                
                Text("\(Int((Double(value) / Double(goal)) * 100))% of goal")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
    }
}

@available(iOS 18.0, *)
struct SecondaryMetricCard: View {
    let icon: String
    let title: String
    let value: String
    let unit: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)
            
            VStack(spacing: 2) {
                Text(value)
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Text(unit)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                
                Text(title)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(8)
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

@available(iOS 18.0, *)
struct LargeProgressRingMetric: View {
    let title: String
    let value: Int
    let goal: Int
    let unit: String
    let color: Color
    let ringSize: CGFloat
    
    var body: some View {
        VStack(spacing: 12) {
            CircularProgress(
                progress: Double(value) / Double(goal),
                color: color,
                size: ringSize
            ) {
                VStack(spacing: 4) {
                    Text("\(value)")
                        .font(.title2)
                        .fontWeight(.bold)
                    Text("/ \(goal)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            VStack(spacing: 4) {
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Text("\(Int((Double(value) / Double(goal)) * 100))% Complete")
                    .font(.caption)
                    .foregroundColor(color)
                
                Text(unit)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
    }
}

@available(iOS 18.0, *)
struct DetailedMetricCard: View {
    let icon: String
    let title: String
    let value: String
    let unit: String
    let subtitle: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            VStack(spacing: 4) {
                HStack(spacing: 2) {
                    Text(value)
                        .font(.title3)
                        .fontWeight(.bold)
                    Text(unit)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .multilineTextAlignment(.center)
                
                Text(subtitle)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding(12)
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

@available(iOS 18.0, *)
struct HealthScoreIndicator: View {
    let score: Int
    
    var body: some View {
        HStack(spacing: 8) {
            ForEach(0..<5) { index in
                Circle()
                    .fill(index < (score / 20) ? scoreColor(score) : Color(.systemGray5))
                    .frame(width: 8, height: 8)
            }
        }
    }
    
    private func scoreColor(_ score: Int) -> Color {
        switch score {
        case 80...100: return .green
        case 60...79: return .blue
        case 40...59: return .orange
        default: return .red
        }
    }
}

// MARK: - Widget Previews

@available(iOS 18.0, *)
struct ComprehensiveHealthWidgets_Previews: PreviewProvider {
    static let sampleEntry = HealthDashboardEntry(
        date: Date(),
        healthData: HealthDashboardData(
            heartRate: 72,
            steps: 8750,
            stepGoal: 10000,
            waterIntake: 48,
            waterGoal: 64,
            sleepHours: 7.5,
            sleepGoal: 8.0,
            caloriesBurned: 420,
            healthScore: 85,
            activeWorkout: nil,
            todayTrend: .improving
        )
    )
    
    static var previews: some View {
        Group {
            HealthDashboardWidgetView(entry: sampleEntry)
                .previewContext(WidgetPreviewContext(family: .systemSmall))
                .previewDisplayName("Small Dashboard")
            
            HealthDashboardWidgetView(entry: sampleEntry)
                .previewContext(WidgetPreviewContext(family: .systemMedium))
                .previewDisplayName("Medium Dashboard")
            
            HealthDashboardWidgetView(entry: sampleEntry)
                .previewContext(WidgetPreviewContext(family: .systemLarge))
                .previewDisplayName("Large Dashboard")
            
            HealthDashboardWidgetView(entry: sampleEntry)
                .previewContext(WidgetPreviewContext(family: .systemExtraLarge))
                .previewDisplayName("Extra Large Dashboard")
        }
    }
}