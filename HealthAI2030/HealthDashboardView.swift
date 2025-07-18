import SwiftUI

struct HealthDashboardView: View {
    @State private var heartRate: Double = 72
    @State private var steps: Int = 8432
    @State private var selectedTab: Int = 0
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    
    var body: some View {
        NavigationView {
            TabView(selection: $selectedTab) {
                VStack(spacing: dynamicTypeSize.isAccessibilitySize ? 30 : 20) {
                    // Header
                    HStack {
                        Text("Health Dashboard")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                            .accessibilityLabel("Health Dashboard")
                            .accessibilityAddTraits(.isHeader)
                        Spacer()
                        Button(action: {
                            // Settings action with haptic feedback
                            let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                            impactFeedback.impactOccurred()
                        }) {
                            Image(systemName: "gear")
                                .font(.title2)
                                .foregroundColor(.primary)
                        }
                        .accessibilityLabel("Settings")
                        .accessibilityHint("Opens settings menu")
                    }
                    .padding(.horizontal)
                    
                    // Health Metrics Cards
                    LazyVGrid(columns: dynamicTypeSize.isAccessibilitySize ? [GridItem(.flexible())] : [
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: dynamicTypeSize.isAccessibilitySize ? 20 : 16) {
                        // Heart Rate Card
                        HealthMetricCard(
                            title: "Heart Rate",
                            value: "\(Int(heartRate))",
                            unit: "BPM",
                            color: .red,
                            icon: "heart.fill"
                        )
                        
                        // Steps Card
                        HealthMetricCard(
                            title: "Steps",
                            value: "\(steps)",
                            unit: "today",
                            color: .blue,
                            icon: "figure.walk"
                        )
                        
                        // Sleep Card
                        HealthMetricCard(
                            title: "Sleep",
                            value: "7.5",
                            unit: "hours",
                            color: .purple,
                            icon: "moon.fill"
                        )
                        
                        // Activity Card
                        HealthMetricCard(
                            title: "Activity",
                            value: "85",
                            unit: "% goal",
                            color: .green,
                            icon: "flame.fill"
                        )
                    }
                    .padding(.horizontal)
                    
                    Spacer()
                }
                .tabItem {
                    Image(systemName: "heart.text.square")
                    Text("Dashboard")
                }
                .tag(0)
                
                // Additional tabs for future features
                Text("Health Insights")
                    .tabItem {
                        Image(systemName: "chart.line.uptrend.xyaxis")
                        Text("Insights")
                    }
                    .tag(1)
                
                Text("Settings")
                    .tabItem {
                        Image(systemName: "gear")
                        Text("Settings")
                    }
                    .tag(2)
            }
            .navigationBarHidden(true)
        }
        .background(Color(UIColor.systemBackground))
    }
}

struct HealthMetricCard: View {
    let title: String
    let value: String
    let unit: String
    let color: Color
    let icon: String
    
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: dynamicTypeSize.isAccessibilitySize ? 16 : 12) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(dynamicTypeSize.isAccessibilitySize ? .title : .title2)
                    .accessibilityHidden(true)
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: dynamicTypeSize.isAccessibilitySize ? 8 : 4) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .accessibilityHidden(true)
                
                HStack(alignment: .bottom, spacing: 4) {
                    Text(value)
                        .font(dynamicTypeSize.isAccessibilitySize ? .title : .title2)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                        .accessibilityHidden(true)
                    
                    Text(unit)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .accessibilityHidden(true)
                }
            }
        }
        .padding(dynamicTypeSize.isAccessibilitySize ? 20 : 16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(UIColor.secondarySystemBackground))
                .shadow(
                    color: colorScheme == .dark ? Color.white.opacity(0.1) : Color.black.opacity(0.1),
                    radius: 4,
                    x: 0,
                    y: 2
                )
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title): \(value) \(unit)")
        .accessibilityAddTraits(.isButton)
        .accessibilityHint("Double tap to view detailed \(title.lowercased()) information")
        .onTapGesture {
            // Add haptic feedback for card tap
            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
            impactFeedback.impactOccurred()
        }
    }
}

#Preview("Light Mode") {
    HealthDashboardView()
        .preferredColorScheme(.light)
}

#Preview("Dark Mode") {
    HealthDashboardView()
        .preferredColorScheme(.dark)
}

#Preview("Accessibility Large") {
    HealthDashboardView()
        .environment(\.dynamicTypeSize, .accessibility3)
}

#Preview("Accessibility Extra Large") {
    HealthDashboardView()
        .environment(\.dynamicTypeSize, .accessibility5)
}