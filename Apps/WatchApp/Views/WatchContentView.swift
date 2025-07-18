import SwiftUI
import WatchKit

@available(watchOS 10.0, *)
struct WatchContentView: View {
    @StateObject private var healthManager = WatchHealthManager.shared
    @State private var showingDetailView = false
    
    var body: some View {
        NavigationStack {
            if #available(watchOS 10.0, *) {
                WatchOptimizedDashboardView()
                    .navigationTitle("HealthAI")
                    .navigationBarTitleDisplayMode(.inline)
            } else {
                // Fallback for earlier watchOS versions
                ScrollView {
                    VStack(spacing: 12) {
                        // Health Summary Card
                        HealthSummaryCard()
                            .padding(.horizontal)
                        
                        // Quick Actions
                        QuickActionsSection()
                            .padding(.horizontal)
                        
                        // Recent Metrics
                        RecentMetricsSection()
                            .padding(.horizontal)
                    }
                    .padding(.vertical)
                }
                .navigationTitle("HealthAI")
                .navigationBarTitleDisplayMode(.inline)
            }
        }
    }
}

// MARK: - Health Summary Card
@available(watchOS 9.0, *)
struct HealthSummaryCard: View {
    @StateObject private var healthManager = WatchHealthManager.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "heart.fill")
                    .foregroundColor(.red)
                    .font(.title3)
                Text("Health Summary")
                    .font(.headline)
            }
            
            Divider()
            
            HStack {
                VStack(alignment: .leading) {
                    Text("Heart Rate")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    Text("\(healthManager.currentHeartRate) BPM")
                        .font(.caption)
                        .bold()
                }
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    Text("Steps")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    Text("\(healthManager.todaySteps)")
                        .font(.caption)
                        .bold()
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

// MARK: - Quick Actions Section
@available(watchOS 9.0, *)
struct QuickActionsSection: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Quick Actions")
                .font(.caption)
                .foregroundColor(.secondary)
            
            HStack(spacing: 12) {
                QuickActionButton(
                    icon: "drop.fill",
                    color: .blue,
                    action: logWaterIntake
                )
                
                QuickActionButton(
                    icon: "figure.walk",
                    color: .green,
                    action: startWorkout
                )
                
                QuickActionButton(
                    icon: "bed.double.fill",
                    color: .purple,
                    action: logSleep
                )
            }
        }
    }
    
    private func logWaterIntake() {
        WKInterfaceDevice.current().play(.click)
        // Log water intake
    }
    
    private func startWorkout() {
        WKInterfaceDevice.current().play(.start)
        // Start workout
    }
    
    private func logSleep() {
        WKInterfaceDevice.current().play(.success)
        // Log sleep
    }
}

// MARK: - Recent Metrics Section
@available(watchOS 9.0, *)
struct RecentMetricsSection: View {
    @StateObject private var healthManager = WatchHealthManager.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recent Metrics")
                .font(.caption)
                .foregroundColor(.secondary)
            
            ForEach(healthManager.recentMetrics) { metric in
                HStack {
                    Image(systemName: metric.icon)
                        .foregroundColor(metric.color)
                        .font(.caption)
                    
                    Text(metric.name)
                        .font(.caption2)
                    
                    Spacer()
                    
                    Text(metric.value)
                        .font(.caption2)
                        .bold()
                }
                .padding(.vertical, 4)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

// MARK: - Quick Action Button
struct QuickActionButton: View {
    let icon: String
    let color: Color
    let action: () -> Void
    @State private var isPressed = false
    
    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 20, weight: .medium))
                .foregroundColor(color)
                .frame(width: 44, height: 44)
                .background(
                    Circle()
                        .fill(color.opacity(isPressed ? 0.3 : 0.1))
                )
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isPressed ? 0.9 : 1.0)
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            isPressed = pressing
        }, perform: {})
    }
}
