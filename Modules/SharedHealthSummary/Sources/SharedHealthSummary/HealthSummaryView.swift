import SwiftUI
import SwiftData

/// A cross-platform health summary view that adapts to iOS, macOS, and tvOS
public struct HealthSummaryView: View {
    @Query(sort: [SortDescriptor(\HealthData.timestamp, order: .reverse)]) private var healthData: [HealthData]
    @State private var selectedTimeRange: TimeRange = .day
    
    public init() {}
    
    public var body: some View {
        VStack(spacing: 20) {
            // Header
            HStack {
                Text("Health Summary")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Spacer()
                
                #if os(iOS) || os(macOS)
                Picker("Time Range", selection: $selectedTimeRange) {
                    ForEach(TimeRange.allCases, id: \.self) { range in
                        Text(range.displayName).tag(range)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .frame(width: 200)
                #endif
            }
            .padding(.horizontal)
            
            // Health metrics grid
            LazyVGrid(columns: gridColumns, spacing: 16) {
                HealthMetricCard(
                    title: "Heart Rate",
                    value: "\(Int(averageHeartRate))",
                    unit: "BPM",
                    icon: "heart.fill",
                    color: .red
                )
                
                HealthMetricCard(
                    title: "Steps",
                    value: "\(totalSteps)",
                    unit: "steps",
                    icon: "figure.walk",
                    color: .green
                )
                
                HealthMetricCard(
                    title: "Sleep",
                    value: String(format: "%.1f", averageSleepHours),
                    unit: "hours",
                    icon: "bed.double.fill",
                    color: .blue
                )
                
                HealthMetricCard(
                    title: "Stress",
                    value: String(format: "%.0f", averageStressLevel),
                    unit: "%",
                    icon: "brain.head.profile",
                    color: .orange
                )
            }
            .padding(.horizontal)
            
            Spacer()
        }
        .accessibilityElement(children: .contain)
    }
    
    private var gridColumns: [GridItem] {
        #if os(tvOS)
        return [
            GridItem(.flexible()),
            GridItem(.flexible()),
            GridItem(.flexible()),
            GridItem(.flexible())
        ]
        #else
        return [
            GridItem(.flexible()),
            GridItem(.flexible())
        ]
        #endif
    }
    
    private var filteredHealthData: [HealthData] {
        let cutoff = Date().addingTimeInterval(-selectedTimeRange.interval)
        return healthData.filter { $0.timestamp >= cutoff }
    }
    
    private var averageHeartRate: Double {
        let heartRates = filteredHealthData.map { $0.heartRate }.filter { $0 > 0 }
        return heartRates.isEmpty ? 0 : heartRates.reduce(0, +) / Double(heartRates.count)
    }
    
    private var totalSteps: Int {
        filteredHealthData.reduce(0) { $0 + $1.steps }
    }
    
    private var averageSleepHours: Double {
        let sleepHours = filteredHealthData.map { $0.sleepHours }.filter { $0 > 0 }
        return sleepHours.isEmpty ? 0 : sleepHours.reduce(0, +) / Double(sleepHours.count)
    }
    
    private var averageStressLevel: Double {
        let stressLevels = filteredHealthData.map { $0.stressLevel }.filter { $0 > 0 }
        return stressLevels.isEmpty ? 0 : stressLevels.reduce(0, +) / Double(stressLevels.count)
    }
}

struct HealthMetricCard: View {
    let title: String
    let value: String
    let unit: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(value)
                .font(.title)
                .fontWeight(.bold)
            
            Text(unit)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text(title)
                .font(.headline)
                .multilineTextAlignment(.center)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title): \(value) \(unit)")
    }
}

enum TimeRange: CaseIterable {
    case day, week, month
    
    var displayName: String {
        switch self {
        case .day: return "Day"
        case .week: return "Week"
        case .month: return "Month"
        }
    }
    
    var interval: TimeInterval {
        switch self {
        case .day: return 24 * 60 * 60
        case .week: return 7 * 24 * 60 * 60
        case .month: return 30 * 24 * 60 * 60
        }
    }
} 