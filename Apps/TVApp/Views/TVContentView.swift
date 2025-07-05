import SwiftUI
import SwiftData

@available(tvOS 18.0, *)
struct TVContentView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var selectedTab = 0
    
    var body: some View {
        NavigationStack {
            TabView(selection: $selectedTab) {
                // Dashboard Tab
                FamilyHealthDashboardView()
                    .tabItem {
                        Image(systemName: "house.fill")
                        Text("Dashboard")
                    }
                    .tag(0)
                
                // Health Data Tab
                TVHealthDataView()
                    .tabItem {
                        Image(systemName: "heart.fill")
                        Text("Health Data")
                    }
                    .tag(1)
                
                // Analytics Tab
                TVAnalyticsView()
                    .tabItem {
                        Image(systemName: "chart.bar.xaxis")
                        Text("Analytics")
                    }
                    .tag(2)
                
                // Activities Tab
                TVActivitiesView()
                    .tabItem {
                        Image(systemName: "figure.run")
                        Text("Activities")
                    }
                    .tag(3)
                
                // AI Copilot Tab
                TVCopilotView()
                    .tabItem {
                        Image(systemName: "brain.head.profile")
                        Text("AI Copilot")
                    }
                    .tag(4)
                
                // Smart Home Tab
                TVSmartHomeControlView()
                    .tabItem {
                        Image(systemName: "house.circle.fill")
                        Text("Smart Home")
                    }
                    .tag(5)
                
                // Settings Tab
                TVSettingsView()
                    .tabItem {
                        Image(systemName: "gear")
                        Text("Settings")
                    }
                    .tag(6)
            }
            .navigationDestination(for: HealthCategory.self) { category in
                TVHealthCategoryDetailView(category: category)
            }
            .navigationDestination(for: SleepData.self) { sleepData in
                TVSleepDetailView(sleepData: sleepData)
            }
            .navigationDestination(for: FamilyMember.self) { member in
                TVFamilyMemberDetailView(member: member)
            }
        }
        .background(Color(.systemBackground))
    }
}

// MARK: - Health Data View
@available(tvOS 18.0, *)
struct TVHealthDataView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var healthRecords: [HealthData]
    
    let healthCategories: [HealthCategory] = [
        .heartRate, .steps, .sleep, .calories, .activity,
        .weight, .bloodPressure, .glucose, .oxygen, .respiratory
    ]
    
    var body: some View {
        ScrollView {
            VStack(spacing: 40) {
                // Header
                VStack(alignment: .leading, spacing: 16) {
                    Text("Health Data")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text("Explore detailed health metrics and trends")
                        .font(.title2)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                // Health Categories Grid
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 30), count: 3), spacing: 30) {
                    ForEach(healthCategories, id: \.self) { category in
                        NavigationLink(value: category) {
                            TVHealthCategoryCard(category: category)
                        }
                        .buttonStyle(CardButtonStyle())
                    }
                }
            }
            .padding(.horizontal, 60)
            .padding(.vertical, 40)
        }
        .background(Color(.systemBackground))
    }
}

// MARK: - Analytics View
@available(tvOS 18.0, *)
struct TVAnalyticsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var healthRecords: [HealthData]
    
    var body: some View {
        ScrollView {
            VStack(spacing: 40) {
                // Header
                VStack(alignment: .leading, spacing: 16) {
                    Text("Health Analytics")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text("Advanced insights and predictive analytics")
                        .font(.title2)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                // Analytics Cards
                VStack(spacing: 30) {
                    TVAnalyticsCard(
                        title: "Health Trends",
                        subtitle: "30-day overview",
                        icon: "chart.line.uptrend.xyaxis",
                        color: .blue
                    )
                    
                    TVAnalyticsCard(
                        title: "Predictive Insights",
                        subtitle: "AI-powered forecasts",
                        icon: "brain.head.profile",
                        color: .purple
                    )
                    
                    TVAnalyticsCard(
                        title: "Risk Assessment",
                        subtitle: "Health risk analysis",
                        icon: "exclamationmark.shield",
                        color: .orange
                    )
                    
                    TVAnalyticsCard(
                        title: "Performance Metrics",
                        subtitle: "Fitness and wellness scores",
                        icon: "chart.bar.fill",
                        color: .green
                    )
                }
            }
            .padding(.horizontal, 60)
            .padding(.vertical, 40)
        }
        .background(Color(.systemBackground))
    }
}

// MARK: - Activities View
@available(tvOS 18.0, *)
struct TVActivitiesView: View {
    @Environment(\.modelContext) private var modelContext
    
    let workoutTypes: [WorkoutType] = [
        .running, .walking, .cycling, .swimming, .yoga, .strength
    ]
    
    var body: some View {
        ScrollView {
            VStack(spacing: 40) {
                // Header
                VStack(alignment: .leading, spacing: 16) {
                    Text("Activities")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text("Start workouts and track your fitness journey")
                        .font(.title2)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                // Workout Types Grid
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 30), count: 3), spacing: 30) {
                    ForEach(workoutTypes, id: \.self) { workoutType in
                        NavigationLink(value: workoutType) {
                            TVWorkoutTypeCard(workoutType: workoutType)
                        }
                        .buttonStyle(CardButtonStyle())
                    }
                }
                
                // Quick Actions
                VStack(alignment: .leading, spacing: 20) {
                    Text("Quick Actions")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    HStack(spacing: 30) {
                        NavigationLink(destination: TVMeditationPlayerView()) {
                            TVQuickActionCard(
                                title: "Start Meditation",
                                icon: "brain.head.profile",
                                color: .purple
                            )
                        }
                        .buttonStyle(CardButtonStyle())
                        
                        NavigationLink(destination: TVLogWaterIntakeView()) {
                            TVQuickActionCard(
                                title: "Log Water",
                                icon: "drop.fill",
                                color: .blue
                            )
                        }
                        .buttonStyle(CardButtonStyle())
                    }
                }
            }
            .padding(.horizontal, 60)
            .padding(.vertical, 40)
        }
        .background(Color(.systemBackground))
    }
}

// MARK: - Supporting Views

@available(tvOS 18.0, *)
struct TVHealthCategoryCard: View {
    let category: HealthCategory
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: category.icon)
                .font(.system(size: 50))
                .foregroundColor(category.color)
            
            Text(category.rawValue)
                .font(.title2)
                .fontWeight(.semibold)
                .multilineTextAlignment(.center)
            
            Text("View details and trends")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(width: 300, height: 200)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(20)
    }
}

@available(tvOS 18.0, *)
struct TVAnalyticsCard: View {
    let title: String
    let subtitle: String
    let icon: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 24) {
            Image(systemName: icon)
                .font(.system(size: 40))
                .foregroundColor(color)
                .frame(width: 80, height: 80)
                .background(color.opacity(0.1))
                .cornerRadius(16)
            
            VStack(alignment: .leading, spacing: 8) {
                Text(title)
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.title2)
                .foregroundColor(.secondary)
        }
        .padding(24)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(16)
    }
}

@available(tvOS 18.0, *)
struct TVWorkoutTypeCard: View {
    let workoutType: WorkoutType
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: workoutType.icon)
                .font(.system(size: 50))
                .foregroundColor(.green)
            
            Text(workoutType.rawValue)
                .font(.title2)
                .fontWeight(.semibold)
                .multilineTextAlignment(.center)
            
            Text("Start workout")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(width: 300, height: 200)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(20)
    }
}

@available(tvOS 18.0, *)
struct TVQuickActionCard: View {
    let title: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 40))
                .foregroundColor(color)
            
            Text(title)
                .font(.headline)
                .fontWeight(.semibold)
                .multilineTextAlignment(.center)
        }
        .frame(width: 250, height: 150)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(16)
    }
}

// MARK: - Button Style
@available(tvOS 18.0, *)
struct CardButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

// MARK: - Data Models
struct SleepData: Hashable {
    let id = UUID()
    let date: Date
    let duration: TimeInterval
    let quality: String
    let stages: [SleepStage]
}

struct SleepStage: Hashable {
    let type: String
    let duration: TimeInterval
    let startTime: Date
}

enum HealthCategory: String, CaseIterable {
    case heartRate = "Heart Rate"
    case steps = "Steps"
    case sleep = "Sleep"
    case calories = "Calories"
    case activity = "Activity"
    case weight = "Weight"
    case bloodPressure = "Blood Pressure"
    case glucose = "Glucose"
    case oxygen = "Oxygen"
    case respiratory = "Respiratory"
    
    var icon: String {
        switch self {
        case .heartRate: return "heart.fill"
        case .steps: return "figure.walk"
        case .sleep: return "bed.double.fill"
        case .calories: return "flame.fill"
        case .activity: return "figure.run"
        case .weight: return "scalemass.fill"
        case .bloodPressure: return "heart.circle.fill"
        case .glucose: return "drop.fill"
        case .oxygen: return "lungs.fill"
        case .respiratory: return "wind"
        }
    }
    
    var color: Color {
        switch self {
        case .heartRate: return .red
        case .steps: return .green
        case .sleep: return .blue
        case .calories: return .orange
        case .activity: return .purple
        case .weight: return .gray
        case .bloodPressure: return .pink
        case .glucose: return .yellow
        case .oxygen: return .cyan
        case .respiratory: return .mint
        }
    }
}

enum WorkoutType: String, CaseIterable {
    case running = "Running"
    case walking = "Walking"
    case cycling = "Cycling"
    case swimming = "Swimming"
    case yoga = "Yoga"
    case strength = "Strength"
    
    var icon: String {
        switch self {
        case .running: return "figure.run"
        case .walking: return "figure.walk"
        case .cycling: return "bicycle"
        case .swimming: return "figure.pool.swim"
        case .yoga: return "figure.mind.and.body"
        case .strength: return "dumbbell.fill"
        }
    }
}

// MARK: - Preview
#Preview {
    TVContentView()
        .modelContainer(for: HealthData.self, inMemory: true)
} 