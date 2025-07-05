import SwiftUI
import Charts
import SwiftData

@available(tvOS 18.0, *)
struct TVSleepDetailView: View {
    let sleepData: SleepData
    @Environment(\.modelContext) private var modelContext
    
    var body: some View {
        ScrollView {
            VStack(spacing: 40) {
                // Header
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Image(systemName: "bed.double.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.blue)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Sleep Analysis")
                                .font(.largeTitle)
                                .fontWeight(.bold)
                            
                            Text("Detailed sleep session breakdown")
                                .font(.title2)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        // Sleep Score
                        VStack(spacing: 8) {
                            Text("Sleep Score")
                                .font(.headline)
                                .foregroundColor(.secondary)
                            
                            Text("85")
                                .font(.system(size: 48, weight: .bold, design: .rounded))
                                .foregroundColor(.green)
                            
                            Text("Good")
                                .font(.subheadline)
                                .foregroundColor(.green)
                        }
                        .padding(20)
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(16)
                    }
                }
                
                // Primary Metrics
                PrimaryMetricsSection(sleepData: sleepData)
                
                // Sleep Stages Chart
                SleepStagesChartSection(sleepData: sleepData)
                
                // Sleep Timeline
                SleepTimelineSection(sleepData: sleepData)
                
                // Sleep Insights
                SleepInsightsSection(sleepData: sleepData)
                
                // Sleep Recommendations
                SleepRecommendationsSection(sleepData: sleepData)
            }
            .padding(.horizontal, 60)
            .padding(.vertical, 40)
        }
        .background(Color(.systemBackground))
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Primary Metrics Section
@available(tvOS 18.0, *)
struct PrimaryMetricsSection: View {
    let sleepData: SleepData
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Sleep Metrics")
                .font(.title)
                .fontWeight(.bold)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 30), count: 4), spacing: 30) {
                TVSleepMetricCard(
                    title: "Time Asleep",
                    value: formatDuration(sleepData.duration),
                    icon: "bed.double.fill",
                    color: .blue
                )
                
                TVSleepMetricCard(
                    title: "Sleep Efficiency",
                    value: "92%",
                    icon: "chart.pie.fill",
                    color: .green
                )
                
                TVSleepMetricCard(
                    title: "Deep Sleep",
                    value: "1h 45m",
                    icon: "moon.fill",
                    color: .purple
                )
                
                TVSleepMetricCard(
                    title: "REM Sleep",
                    value: "1h 30m",
                    icon: "brain.head.profile",
                    color: .orange
                )
            }
        }
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let hours = Int(duration) / 3600
        let minutes = Int(duration) % 3600 / 60
        return "\(hours)h \(minutes)m"
    }
}

// MARK: - Sleep Stages Chart Section
@available(tvOS 18.0, *)
struct SleepStagesChartSection: View {
    let sleepData: SleepData
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Sleep Stages")
                .font(.title)
                .fontWeight(.bold)
            
            VStack(spacing: 16) {
                // Sleep Stages Bar Chart
                Chart {
                    ForEach(sleepData.stages, id: \.startTime) { stage in
                        BarMark(
                            x: .value("Time", stage.startTime),
                            y: .value("Duration", stage.duration / 60), // Convert to minutes
                            width: .fixed(20)
                        )
                        .foregroundStyle(getStageColor(stage.type))
                    }
                }
                .frame(height: 200)
                .chartXAxis {
                    AxisMarks(values: .automatic) { value in
                        AxisGridLine()
                        AxisValueLabel(format: .dateTime.hour())
                    }
                }
                .chartYAxis {
                    AxisMarks(values: .automatic) { value in
                        AxisGridLine()
                        AxisValueLabel(format: .number)
                    }
                }
                
                // Sleep Stages Legend
                HStack(spacing: 30) {
                    SleepStageLegendItem(
                        color: .purple,
                        title: "Deep Sleep",
                        duration: "1h 45m"
                    )
                    
                    SleepStageLegendItem(
                        color: .blue,
                        title: "Core Sleep",
                        duration: "4h 15m"
                    )
                    
                    SleepStageLegendItem(
                        color: .orange,
                        title: "REM Sleep",
                        duration: "1h 30m"
                    )
                    
                    SleepStageLegendItem(
                        color: .gray,
                        title: "Awake",
                        duration: "15m"
                    )
                }
            }
            .padding(24)
            .background(Color(.secondarySystemBackground))
            .cornerRadius(16)
        }
    }
    
    private func getStageColor(_ stageType: String) -> Color {
        switch stageType.lowercased() {
        case "deep": return .purple
        case "core": return .blue
        case "rem": return .orange
        case "awake": return .gray
        default: return .blue
        }
    }
}

// MARK: - Sleep Timeline Section
@available(tvOS 18.0, *)
struct SleepTimelineSection: View {
    let sleepData: SleepData
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Sleep Timeline")
                .font(.title)
                .fontWeight(.bold)
            
            VStack(spacing: 16) {
                ForEach(getTimelineEvents(), id: \.time) { event in
                    HStack(spacing: 16) {
                        Circle()
                            .fill(event.color)
                            .frame(width: 12, height: 12)
                        
                        Text(event.time)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .frame(width: 80, alignment: .leading)
                        
                        Text(event.description)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                    }
                }
            }
            .padding(24)
            .background(Color(.secondarySystemBackground))
            .cornerRadius(16)
        }
    }
    
    private func getTimelineEvents() -> [TimelineEvent] {
        return [
            TimelineEvent(time: "10:30 PM", description: "Went to bed", color: .blue),
            TimelineEvent(time: "10:45 PM", description: "Fell asleep", color: .green),
            TimelineEvent(time: "2:15 AM", description: "Brief wake-up", color: .orange),
            TimelineEvent(time: "2:20 AM", description: "Fell back asleep", color: .green),
            TimelineEvent(time: "6:30 AM", description: "Woke up", color: .red)
        ]
    }
}

// MARK: - Sleep Insights Section
@available(tvOS 18.0, *)
struct SleepInsightsSection: View {
    let sleepData: SleepData
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Sleep Insights")
                .font(.title)
                .fontWeight(.bold)
            
            VStack(spacing: 16) {
                TVSleepInsightRow(
                    icon: "moon.stars.fill",
                    title: "Excellent Deep Sleep",
                    description: "You achieved 1h 45m of deep sleep, which is above the recommended range for optimal recovery.",
                    color: .green
                )
                
                TVSleepInsightRow(
                    icon: "clock.fill",
                    title: "Consistent Sleep Schedule",
                    description: "Your sleep schedule has been consistent this week, which helps regulate your circadian rhythm.",
                    color: .blue
                )
                
                TVSleepInsightRow(
                    icon: "exclamationmark.triangle.fill",
                    title: "Room for Improvement",
                    description: "Consider reducing screen time before bed to improve sleep onset latency.",
                    color: .orange
                )
            }
        }
    }
}

// MARK: - Sleep Recommendations Section
@available(tvOS 18.0, *)
struct SleepRecommendationsSection: View {
    let sleepData: SleepData
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Sleep Recommendations")
                .font(.title)
                .fontWeight(.bold)
            
            VStack(spacing: 16) {
                TVSleepRecommendationRow(
                    title: "Optimize Sleep Environment",
                    description: "Keep your bedroom cool (65-68°F) and dark for better sleep quality.",
                    action: "View Tips"
                )
                
                TVSleepRecommendationRow(
                    title: "Establish Bedtime Routine",
                    description: "Create a relaxing 30-minute routine before bed to signal your body it's time to sleep.",
                    action: "Create Routine"
                )
                
                TVSleepRecommendationRow(
                    title: "Monitor Sleep Patterns",
                    description: "Track your sleep for the next week to identify patterns and optimize your schedule.",
                    action: "Start Tracking"
                )
            }
        }
    }
}

// MARK: - Supporting Views

@available(tvOS 18.0, *)
struct TVSleepMetricCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 32))
                .foregroundColor(color)
            
            Text(value)
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundColor(.primary)
            
            Text(title)
                .font(.headline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(width: 200, height: 150)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
}

@available(tvOS 18.0, *)
struct SleepStageLegendItem: View {
    let color: Color
    let title: String
    let duration: String
    
    var body: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(color)
                .frame(width: 16, height: 16)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(duration)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}

@available(tvOS 18.0, *)
struct TVSleepInsightRow: View {
    let icon: String
    let title: String
    let description: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(color)
                .frame(width: 40, height: 40)
                .background(color.opacity(0.1))
                .cornerRadius(8)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding(16)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
}

@available(tvOS 18.0, *)
struct TVSleepRecommendationRow: View {
    let title: String
    let description: String
    let action: String
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Button(action: {}) {
                Text(action)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
            .buttonStyle(CardButtonStyle())
        }
        .padding(16)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
}

// MARK: - Data Models
struct TimelineEvent {
    let time: String
    let description: String
    let color: Color
}

// MARK: - Preview
#Preview {
    let sampleSleepData = SleepData(
        date: Date(),
        duration: 7.5 * 3600, // 7.5 hours
        quality: "Good",
        stages: [
            SleepStage(type: "Deep", duration: 1.75 * 3600, startTime: Date()),
            SleepStage(type: "Core", duration: 4.25 * 3600, startTime: Date()),
            SleepStage(type: "REM", duration: 1.5 * 3600, startTime: Date()),
            SleepStage(type: "Awake", duration: 0.25 * 3600, startTime: Date())
        ]
    )
    
    return TVSleepDetailView(sleepData: sampleSleepData)
        .modelContainer(for: HealthData.self, inMemory: true)
} 