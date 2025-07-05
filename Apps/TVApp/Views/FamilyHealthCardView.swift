import SwiftUI
import SwiftData

struct FamilyHealthCardView: View {
    let familyMember: FamilyMember
    @State private var showingDetails = false
    @State private var selectedMetric: HealthMetric = .overview
    
    enum HealthMetric: String, CaseIterable {
        case overview = "Overview"
        case heartRate = "Heart Rate"
        case activity = "Activity"
        case sleep = "Sleep"
        case nutrition = "Nutrition"
        case medications = "Medications"
        
        var icon: String {
            switch self {
            case .overview: return "person.fill"
            case .heartRate: return "heart.fill"
            case .activity: return "figure.run"
            case .sleep: return "bed.double.fill"
            case .nutrition: return "fork.knife"
            case .medications: return "pill.fill"
            }
        }
        
        var color: Color {
            switch self {
            case .overview: return .blue
            case .heartRate: return .red
            case .activity: return .green
            case .sleep: return .indigo
            case .nutrition: return .orange
            case .medications: return .purple
            }
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            CardHeader(familyMember: familyMember)
            
            // Metric Selector
            MetricSelector(selectedMetric: $selectedMetric)
            
            // Content Area
            CardContent(
                familyMember: familyMember,
                selectedMetric: selectedMetric
            )
        }
        .background(Color(.systemBackground))
        .cornerRadius(24)
        .shadow(radius: 10)
        .onTapGesture {
            showingDetails = true
        }
        .sheet(isPresented: $showingDetails) {
            FamilyMemberDetailView(familyMember: familyMember)
        }
    }
}

struct CardHeader: View {
    let familyMember: FamilyMember
    
    var body: some View {
        HStack(spacing: 20) {
            // Profile Image
            ZStack {
                Circle()
                    .fill(familyMember.profileColor)
                    .frame(width: 80, height: 80)
                
                Text(familyMember.initials)
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(.white)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text(familyMember.name)
                    .font(.title)
                    .fontWeight(.bold)
                
                Text(familyMember.relationship)
                    .font(.headline)
                    .foregroundColor(.secondary)
                
                Text("\(familyMember.age) years old")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Health Status Indicator
            VStack(spacing: 8) {
                Circle()
                    .fill(Color.green)
                    .frame(width: 16, height: 16)
                
                Text("Healthy")
                    .font(.caption)
                    .foregroundColor(.green)
            }
        }
        .padding(24)
        .background(Color(.secondarySystemBackground))
    }
}

struct MetricSelector: View {
    @Binding var selectedMetric: FamilyHealthCardView.HealthMetric
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 20) {
                ForEach(FamilyHealthCardView.HealthMetric.allCases, id: \.self) { metric in
                    MetricButton(
                        metric: metric,
                        isSelected: selectedMetric == metric
                    ) {
                        selectedMetric = metric
                    }
                }
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
        }
        .background(Color(.tertiarySystemBackground))
    }
}

struct MetricButton: View {
    let metric: FamilyHealthCardView.HealthMetric
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: metric.icon)
                    .font(.system(size: 24))
                    .foregroundColor(isSelected ? .white : metric.color)
                
                Text(metric.rawValue)
                    .font(.caption)
                    .foregroundColor(isSelected ? .white : .primary)
            }
            .frame(width: 100, height: 80)
            .background(isSelected ? metric.color : Color(.quaternarySystemBackground))
            .cornerRadius(12)
        }
        .buttonStyle(CardButtonStyle())
    }
}

struct CardContent: View {
    let familyMember: FamilyMember
    let selectedMetric: FamilyHealthCardView.HealthMetric
    
    var body: some View {
        VStack(spacing: 20) {
            switch selectedMetric {
            case .overview:
                OverviewContent(familyMember: familyMember)
            case .heartRate:
                HeartRateContent(familyMember: familyMember)
            case .activity:
                ActivityContent(familyMember: familyMember)
            case .sleep:
                SleepContent(familyMember: familyMember)
            case .nutrition:
                NutritionContent(familyMember: familyMember)
            case .medications:
                MedicationsContent(familyMember: familyMember)
            }
        }
        .padding(24)
    }
}

struct OverviewContent: View {
    let familyMember: FamilyMember
    
    var body: some View {
        VStack(spacing: 24) {
            // Quick Stats Grid
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 20) {
                QuickStatView(
                    title: "Heart Rate",
                    value: "\(familyMember.heartRate)",
                    unit: "BPM",
                    icon: "heart.fill",
                    color: .red
                )
                
                QuickStatView(
                    title: "Steps",
                    value: "\(familyMember.dailySteps)",
                    unit: "steps",
                    icon: "figure.walk",
                    color: .green
                )
                
                QuickStatView(
                    title: "Sleep",
                    value: "7.5",
                    unit: "hours",
                    icon: "bed.double.fill",
                    color: .blue
                )
                
                QuickStatView(
                    title: "Calories",
                    value: "2,145",
                    unit: "kcal",
                    icon: "flame.fill",
                    color: .orange
                )
            }
            
            // Health Summary
            VStack(alignment: .leading, spacing: 12) {
                Text("Health Summary")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Text("\(familyMember.name) is maintaining good health with regular activity and proper sleep patterns. All vital signs are within normal ranges.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(3)
            }
        }
    }
}

struct HeartRateContent: View {
    let familyMember: FamilyMember
    
    var body: some View {
        VStack(spacing: 24) {
            // Current Heart Rate
            VStack(spacing: 16) {
                Text("Current Heart Rate")
                    .font(.headline)
                    .foregroundColor(.secondary)
                
                HStack(alignment: .bottom, spacing: 8) {
                    Text("\(familyMember.heartRate)")
                        .font(.system(size: 64, weight: .bold, design: .rounded))
                        .foregroundColor(.red)
                    
                    Text("BPM")
                        .font(.title2)
                        .foregroundColor(.secondary)
                }
                
                Text("Resting • Normal Range")
                    .font(.caption)
                    .foregroundColor(.green)
            }
            
            // Heart Rate Zones
            VStack(alignment: .leading, spacing: 16) {
                Text("Heart Rate Zones")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                VStack(spacing: 12) {
                    HeartRateZoneRow(
                        zone: "Resting",
                        range: "60-100",
                        percentage: 85,
                        color: .green
                    )
                    
                    HeartRateZoneRow(
                        zone: "Light Activity",
                        range: "100-140",
                        percentage: 12,
                        color: .blue
                    )
                    
                    HeartRateZoneRow(
                        zone: "Moderate",
                        range: "140-170",
                        percentage: 3,
                        color: .orange
                    )
                }
            }
        }
    }
}

struct HeartRateZoneRow: View {
    let zone: String
    let range: String
    let percentage: Int
    let color: Color
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(zone)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(range)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Text("\(percentage)%")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(color)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(color.opacity(0.1))
        .cornerRadius(8)
    }
}

struct ActivityContent: View {
    let familyMember: FamilyMember
    
    var body: some View {
        VStack(spacing: 24) {
            // Daily Activity Summary
            VStack(spacing: 16) {
                Text("Today's Activity")
                    .font(.headline)
                    .foregroundColor(.secondary)
                
                HStack(alignment: .bottom, spacing: 8) {
                    Text("\(familyMember.dailySteps)")
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .foregroundColor(.green)
                    
                    Text("steps")
                        .font(.title3)
                        .foregroundColor(.secondary)
                }
                
                Text("Goal: 10,000 steps")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            // Activity Progress
            VStack(alignment: .leading, spacing: 16) {
                Text("Activity Progress")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                VStack(spacing: 12) {
                    ActivityProgressRow(
                        activity: "Steps",
                        current: familyMember.dailySteps,
                        goal: 10000,
                        icon: "figure.walk",
                        color: .green
                    )
                    
                    ActivityProgressRow(
                        activity: "Calories",
                        current: 2145,
                        goal: 2500,
                        icon: "flame.fill",
                        color: .orange
                    )
                    
                    ActivityProgressRow(
                        activity: "Active Minutes",
                        current: 45,
                        goal: 60,
                        icon: "clock.fill",
                        color: .blue
                    )
                }
            }
        }
    }
}

struct ActivityProgressRow: View {
    let activity: String
    let current: Int
    let goal: Int
    let icon: String
    let color: Color
    
    private var progress: Double {
        Double(current) / Double(goal)
    }
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.subheadline)
                
                Text(activity)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Spacer()
                
                Text("\(current)/\(goal)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            ProgressView(value: progress)
                .progressViewStyle(LinearProgressViewStyle(tint: color))
        }
    }
}

struct SleepContent: View {
    let familyMember: FamilyMember
    
    var body: some View {
        VStack(spacing: 24) {
            // Sleep Summary
            VStack(spacing: 16) {
                Text("Last Night's Sleep")
                    .font(.headline)
                    .foregroundColor(.secondary)
                
                HStack(alignment: .bottom, spacing: 8) {
                    Text("7.5")
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .foregroundColor(.blue)
                    
                    Text("hours")
                        .font(.title3)
                        .foregroundColor(.secondary)
                }
                
                Text("Good Quality Sleep")
                    .font(.subheadline)
                    .foregroundColor(.green)
            }
            
            // Sleep Stages
            VStack(alignment: .leading, spacing: 16) {
                Text("Sleep Stages")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                VStack(spacing: 12) {
                    SleepStageRow(
                        stage: "Deep Sleep",
                        duration: "2.1h",
                        percentage: 28,
                        color: .purple
                    )
                    
                    SleepStageRow(
                        stage: "Light Sleep",
                        duration: "4.2h",
                        percentage: 56,
                        color: .blue
                    )
                    
                    SleepStageRow(
                        stage: "REM Sleep",
                        duration: "1.2h",
                        percentage: 16,
                        color: .cyan
                    )
                }
            }
        }
    }
}

struct SleepStageRow: View {
    let stage: String
    let duration: String
    let percentage: Int
    let color: Color
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(stage)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(duration)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Text("\(percentage)%")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(color)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(color.opacity(0.1))
        .cornerRadius(8)
    }
}

struct NutritionContent: View {
    let familyMember: FamilyMember
    
    var body: some View {
        VStack(spacing: 24) {
            // Daily Nutrition Summary
            VStack(spacing: 16) {
                Text("Today's Nutrition")
                    .font(.headline)
                    .foregroundColor(.secondary)
                
                HStack(alignment: .bottom, spacing: 8) {
                    Text("2,145")
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .foregroundColor(.orange)
                    
                    Text("calories")
                        .font(.title3)
                        .foregroundColor(.secondary)
                }
                
                Text("Goal: 2,500 calories")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            // Nutrition Breakdown
            VStack(alignment: .leading, spacing: 16) {
                Text("Nutrition Breakdown")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                VStack(spacing: 12) {
                    NutritionRow(
                        nutrient: "Protein",
                        amount: "85g",
                        goal: "120g",
                        color: .red
                    )
                    
                    NutritionRow(
                        nutrient: "Carbs",
                        amount: "250g",
                        goal: "300g",
                        color: .green
                    )
                    
                    NutritionRow(
                        nutrient: "Fat",
                        amount: "65g",
                        goal: "80g",
                        color: .yellow
                    )
                    
                    NutritionRow(
                        nutrient: "Water",
                        amount: "6/8",
                        goal: "8 glasses",
                        color: .blue
                    )
                }
            }
        }
    }
}

struct NutritionRow: View {
    let nutrient: String
    let amount: String
    let goal: String
    let color: Color
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(nutrient)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(goal)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Text(amount)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(color)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(color.opacity(0.1))
        .cornerRadius(8)
    }
}

struct MedicationsContent: View {
    let familyMember: FamilyMember
    
    var body: some View {
        VStack(spacing: 24) {
            // Medication Summary
            VStack(spacing: 16) {
                Text("Medications")
                    .font(.headline)
                    .foregroundColor(.secondary)
                
                Text("2 Active Medications")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.purple)
            }
            
            // Medication List
            VStack(alignment: .leading, spacing: 16) {
                Text("Today's Schedule")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                VStack(spacing: 12) {
                    MedicationRow(
                        name: "Vitamin D",
                        dosage: "1000 IU",
                        time: "9:00 AM",
                        status: .taken
                    )
                    
                    MedicationRow(
                        name: "Omega-3",
                        dosage: "1000mg",
                        time: "6:00 PM",
                        status: .pending
                    )
                }
            }
        }
    }
}

struct MedicationRow: View {
    let name: String
    let dosage: String
    let time: String
    let status: MedicationStatus
    
    enum MedicationStatus {
        case taken, pending, missed
        
        var color: Color {
            switch self {
            case .taken: return .green
            case .pending: return .orange
            case .missed: return .red
            }
        }
        
        var text: String {
            switch self {
            case .taken: return "Taken"
            case .pending: return "Pending"
            case .missed: return "Missed"
            }
        }
    }
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(dosage)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text(time)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(status.text)
                    .font(.caption)
                    .foregroundColor(status.color)
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(status.color.opacity(0.1))
        .cornerRadius(8)
    }
}

struct QuickStatView: View {
    let title: String
    let value: String
    let unit: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(color)
            
            VStack(spacing: 4) {
                HStack(alignment: .bottom, spacing: 2) {
                    Text(value)
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text(unit)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(16)
        .background(Color(.tertiarySystemBackground))
        .cornerRadius(12)
    }
}

struct FamilyMemberDetailView: View {
    let familyMember: FamilyMember
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 30) {
            Text("\(familyMember.name)'s Health Details")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            // Detailed health information would go here
            Text("Detailed health information and analytics for \(familyMember.name)")
                .font(.title2)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Button("Close") {
                dismiss()
            }
            .buttonStyle(.borderedProminent)
        }
        .padding(40)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
    }
}

#Preview {
    FamilyHealthCardView(familyMember: FamilyMember(
        name: "John Doe",
        relationship: "Father",
        age: 35,
        profileColor: .blue
    ))
} 