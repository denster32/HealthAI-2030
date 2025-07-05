import SwiftUI
import Charts
import SwiftData

@available(tvOS 18.0, *)
struct TVFamilyMemberDetailView: View {
    let member: FamilyMember
    @Environment(\.modelContext) private var modelContext
    @Query private var healthRecords: [HealthData]
    @State private var selectedTimeRange: TimeRange = .week
    
    enum TimeRange: String, CaseIterable {
        case day = "24 Hours"
        case week = "7 Days"
        case month = "30 Days"
        case year = "1 Year"
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 40) {
                // Header
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        // Profile Image
                        ZStack {
                            Circle()
                                .fill(member.profileColor)
                                .frame(width: 120, height: 120)
                            
                            Text(member.initials)
                                .font(.system(size: 48, weight: .bold))
                                .foregroundColor(.white)
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text(member.name)
                                .font(.largeTitle)
                                .fontWeight(.bold)
                            
                            Text("\(member.relationship) • \(member.age) years old")
                                .font(.title2)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        // Time Range Picker
                        Picker("Time Range", selection: $selectedTimeRange) {
                            ForEach(TimeRange.allCases, id: \.self) { range in
                                Text(range.rawValue).tag(range)
                            }
                        }
                        .pickerStyle(SegmentedPickerStyle())
                        .frame(width: 400)
                    }
                }
                
                // Health Overview
                HealthOverviewSection(member: member, timeRange: selectedTimeRange)
                
                // Activity Summary
                ActivitySummarySection(member: member, timeRange: selectedTimeRange)
                
                // Health Trends
                HealthTrendsSection(member: member, timeRange: selectedTimeRange)
                
                // Recent Activities
                RecentActivitiesSection(member: member)
                
                // Health Goals
                HealthGoalsSection(member: member)
            }
            .padding(.horizontal, 60)
            .padding(.vertical, 40)
        }
        .background(Color(.systemBackground))
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Health Overview Section
@available(tvOS 18.0, *)
struct HealthOverviewSection: View {
    let member: FamilyMember
    let timeRange: TVFamilyMemberDetailView.TimeRange
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Health Overview")
                .font(.title)
                .fontWeight(.bold)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 30), count: 4), spacing: 30) {
                TVFamilyMetricCard(
                    title: "Heart Rate",
                    value: "\(member.heartRate)",
                    unit: "BPM",
                    icon: "heart.fill",
                    color: .red,
                    trend: "+3",
                    trendDirection: .up
                )
                
                TVFamilyMetricCard(
                    title: "Daily Steps",
                    value: "\(member.dailySteps)",
                    unit: "steps",
                    icon: "figure.walk",
                    color: .green,
                    trend: "+12%",
                    trendDirection: .up
                )
                
                TVFamilyMetricCard(
                    title: "Sleep",
                    value: "7.5",
                    unit: "hours",
                    icon: "bed.double.fill",
                    color: .blue,
                    trend: "-0.3",
                    trendDirection: .down
                )
                
                TVFamilyMetricCard(
                    title: "Activity",
                    value: "85",
                    unit: "%",
                    icon: "figure.run",
                    color: .purple,
                    trend: "+5%",
                    trendDirection: .up
                )
            }
        }
    }
}

// MARK: - Activity Summary Section
@available(tvOS 18.0, *)
struct ActivitySummarySection: View {
    let member: FamilyMember
    let timeRange: TVFamilyMemberDetailView.TimeRange
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Activity Summary")
                .font(.title)
                .fontWeight(.bold)
            
            VStack(spacing: 16) {
                // Activity Chart
                Chart {
                    ForEach(getActivityData(), id: \.date) { dataPoint in
                        BarMark(
                            x: .value("Date", dataPoint.date),
                            y: .value("Activity", dataPoint.value)
                        )
                        .foregroundStyle(Color.green.gradient)
                    }
                }
                .frame(height: 200)
                .chartXAxis {
                    AxisMarks(values: .automatic) { value in
                        AxisGridLine()
                        AxisValueLabel(format: .dateTime.weekday())
                    }
                }
                .chartYAxis {
                    AxisMarks(values: .automatic) { value in
                        AxisGridLine()
                        AxisValueLabel()
                    }
                }
                
                // Activity Stats
                HStack(spacing: 40) {
                    ActivityStatItem(
                        title: "Weekly Goal",
                        value: "5/7 days",
                        color: .green
                    )
                    
                    ActivityStatItem(
                        title: "Avg. Steps",
                        value: "8,234",
                        color: .blue
                    )
                    
                    ActivityStatItem(
                        title: "Workouts",
                        value: "3 this week",
                        color: .orange
                    )
                }
            }
            .padding(24)
            .background(Color(.secondarySystemBackground))
            .cornerRadius(16)
        }
    }
    
    private func getActivityData() -> [ActivityDataPoint] {
        let calendar = Calendar.current
        let now = Date()
        var dataPoints: [ActivityDataPoint] = []
        
        for i in 0..<7 {
            let date = calendar.date(byAdding: .day, value: -i, to: now) ?? now
            let steps = Int.random(in: 6000...12000)
            dataPoints.append(ActivityDataPoint(date: date, value: steps))
        }
        
        return dataPoints.reversed()
    }
}

// MARK: - Health Trends Section
@available(tvOS 18.0, *)
struct HealthTrendsSection: View {
    let member: FamilyMember
    let timeRange: TVFamilyMemberDetailView.TimeRange
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Health Trends")
                .font(.title)
                .fontWeight(.bold)
            
            VStack(spacing: 16) {
                // Heart Rate Trend
                Chart {
                    ForEach(getHeartRateData(), id: \.date) { dataPoint in
                        LineMark(
                            x: .value("Date", dataPoint.date),
                            y: .value("Heart Rate", dataPoint.value)
                        )
                        .foregroundStyle(Color.red)
                        .lineStyle(StrokeStyle(lineWidth: 3))
                    }
                }
                .frame(height: 150)
                .chartXAxis {
                    AxisMarks(values: .automatic) { value in
                        AxisGridLine()
                        AxisValueLabel(format: .dateTime.hour())
                    }
                }
                .chartYAxis {
                    AxisMarks(values: .automatic) { value in
                        AxisGridLine()
                        AxisValueLabel()
                    }
                }
                
                Text("Heart Rate Trend (24 hours)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .padding(24)
            .background(Color(.secondarySystemBackground))
            .cornerRadius(16)
        }
    }
    
    private func getHeartRateData() -> [HeartRateDataPoint] {
        let calendar = Calendar.current
        let now = Date()
        var dataPoints: [HeartRateDataPoint] = []
        
        for i in 0..<24 {
            let date = calendar.date(byAdding: .hour, value: -i, to: now) ?? now
            let heartRate = Int.random(in: 60...85)
            dataPoints.append(HeartRateDataPoint(date: date, value: heartRate))
        }
        
        return dataPoints.reversed()
    }
}

// MARK: - Recent Activities Section
@available(tvOS 18.0, *)
struct RecentActivitiesSection: View {
    let member: FamilyMember
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Recent Activities")
                .font(.title)
                .fontWeight(.bold)
            
            VStack(spacing: 16) {
                ForEach(getRecentActivities(), id: \.id) { activity in
                    TVActivityRow(activity: activity)
                }
            }
        }
    }
    
    private func getRecentActivities() -> [FamilyActivity] {
        return [
            FamilyActivity(
                id: UUID(),
                type: "Running",
                duration: "30 minutes",
                time: "2 hours ago",
                icon: "figure.run",
                color: .green
            ),
            FamilyActivity(
                id: UUID(),
                type: "Water Intake",
                amount: "16 oz",
                time: "3 hours ago",
                icon: "drop.fill",
                color: .blue
            ),
            FamilyActivity(
                id: UUID(),
                type: "Meditation",
                duration: "15 minutes",
                time: "5 hours ago",
                icon: "brain.head.profile",
                color: .purple
            ),
            FamilyActivity(
                id: UUID(),
                type: "Sleep",
                duration: "7.5 hours",
                time: "12 hours ago",
                icon: "bed.double.fill",
                color: .indigo
            )
        ]
    }
}

// MARK: - Health Goals Section
@available(tvOS 18.0, *)
struct HealthGoalsSection: View {
    let member: FamilyMember
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Health Goals")
                .font(.title)
                .fontWeight(.bold)
            
            VStack(spacing: 16) {
                ForEach(getHealthGoals(), id: \.id) { goal in
                    TVHealthGoalRow(goal: goal)
                }
            }
        }
    }
    
    private func getHealthGoals() -> [HealthGoal] {
        return [
            HealthGoal(
                id: UUID(),
                title: "Daily Steps",
                target: "10,000",
                current: "8,234",
                unit: "steps",
                progress: 0.82,
                color: .green
            ),
            HealthGoal(
                id: UUID(),
                title: "Sleep Duration",
                target: "8",
                current: "7.5",
                unit: "hours",
                progress: 0.94,
                color: .blue
            ),
            HealthGoal(
                id: UUID(),
                title: "Workout Sessions",
                target: "5",
                current: "3",
                unit: "sessions",
                progress: 0.6,
                color: .orange
            )
        ]
    }
}

// MARK: - Supporting Views

@available(tvOS 18.0, *)
struct TVFamilyMetricCard: View {
    let title: String
    let value: String
    let unit: String
    let icon: String
    let color: Color
    let trend: String
    let trendDirection: TVHealthCategoryDetailView.KeyMetricsSection.TrendDirection
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 32))
                .foregroundColor(color)
            
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(value)
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
                
                Text(unit)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Text(title)
                .font(.headline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            HStack(spacing: 4) {
                Image(systemName: trendDirection == .up ? "arrow.up.right" : "arrow.down.right")
                    .font(.caption)
                    .foregroundColor(trendDirection == .up ? .green : .red)
                
                Text(trend)
                    .font(.caption)
                    .foregroundColor(trendDirection == .up ? .green : .red)
            }
        }
        .frame(width: 200, height: 150)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
}

@available(tvOS 18.0, *)
struct ActivityStatItem: View {
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Text(title)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(color)
        }
    }
}

@available(tvOS 18.0, *)
struct TVActivityRow: View {
    let activity: FamilyActivity
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: activity.icon)
                .font(.system(size: 24))
                .foregroundColor(activity.color)
                .frame(width: 40, height: 40)
                .background(activity.color.opacity(0.1))
                .cornerRadius(8)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(activity.type)
                    .font(.headline)
                    .fontWeight(.semibold)
                
                if let duration = activity.duration {
                    Text(duration)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                } else if let amount = activity.amount {
                    Text(amount)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            Text(activity.time)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding(16)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
}

@available(tvOS 18.0, *)
struct TVHealthGoalRow: View {
    let goal: HealthGoal
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(goal.title)
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Text("\(goal.current)/\(goal.target) \(goal.unit)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            // Progress Bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 8)
                        .cornerRadius(4)
                    
                    Rectangle()
                        .fill(goal.color)
                        .frame(width: geometry.size.width * goal.progress, height: 8)
                        .cornerRadius(4)
                }
            }
            .frame(height: 8)
            
            Text("\(Int(goal.progress * 100))% Complete")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(16)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
}

// MARK: - Data Models
struct ActivityDataPoint {
    let date: Date
    let value: Int
}

struct HeartRateDataPoint {
    let date: Date
    let value: Int
}

struct FamilyActivity {
    let id: UUID
    let type: String
    let duration: String?
    let amount: String?
    let time: String
    let icon: String
    let color: Color
}

struct HealthGoal {
    let id: UUID
    let title: String
    let target: String
    let current: String
    let unit: String
    let progress: Double
    let color: Color
}

// MARK: - Preview
#Preview {
    let sampleMember = FamilyMember(
        name: "John Doe",
        relationship: "Father",
        age: 35,
        profileColor: .blue,
        heartRate: 72,
        dailySteps: 8234
    )
    
    return TVFamilyMemberDetailView(member: sampleMember)
        .modelContainer(for: HealthData.self, inMemory: true)
} 