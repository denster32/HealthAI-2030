import SwiftUI
import SwiftData

@available(tvOS 18.0, *)
struct TVLogWaterIntakeView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var selectedAmount: WaterAmount = .eightOz
    @State private var showingConfirmation = false
    @State private var animationScale: CGFloat = 1.0
    
    enum WaterAmount: CaseIterable {
        case fourOz, eightOz, twelveOz, sixteenOz, twentyOz, custom
        
        var amount: Int {
            switch self {
            case .fourOz: return 4
            case .eightOz: return 8
            case .twelveOz: return 12
            case .sixteenOz: return 16
            case .twentyOz: return 20
            case .custom: return 0
            }
        }
        
        var displayText: String {
            switch self {
            case .fourOz: return "4 oz"
            case .eightOz: return "8 oz"
            case .twelveOz: return "12 oz"
            case .sixteenOz: return "16 oz"
            case .twentyOz: return "20 oz"
            case .custom: return "Custom"
            }
        }
        
        var icon: String {
            switch self {
            case .fourOz: return "drop.fill"
            case .eightOz: return "drop.fill"
            case .twelveOz: return "drop.fill"
            case .sixteenOz: return "drop.fill"
            case .twentyOz: return "drop.fill"
            case .custom: return "plus.circle.fill"
            }
        }
    }
    
    var body: some View {
        ZStack {
            // Background
            LinearGradient(
                colors: [
                    Color.blue.opacity(0.1),
                    Color.cyan.opacity(0.1),
                    Color.blue.opacity(0.1)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 40) {
                // Header
                VStack(spacing: 16) {
                    Image(systemName: "drop.fill")
                        .font(.system(size: 80))
                        .foregroundColor(.blue)
                        .scaleEffect(animationScale)
                        .animation(.easeInOut(duration: 2).repeatForever(autoreverses: true), value: animationScale)
                    
                    Text("Log Water Intake")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text("Select the amount of water you consumed")
                        .font(.title2)
                        .foregroundColor(.secondary)
                }
                
                // Water Amount Selection
                VStack(spacing: 20) {
                    Text("Choose Amount")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 30), count: 3), spacing: 30) {
                        ForEach(WaterAmount.allCases, id: \.self) { amount in
                            WaterAmountCard(
                                amount: amount,
                                isSelected: selectedAmount == amount
                            ) {
                                selectedAmount = amount
                            }
                        }
                    }
                }
                
                // Daily Progress
                DailyWaterProgressView()
                
                // Action Buttons
                HStack(spacing: 40) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .buttonStyle(TVButtonStyle())
                    
                    Button("Log Water") {
                        logWaterIntake()
                    }
                    .buttonStyle(TVButtonStyle())
                    .disabled(selectedAmount == .custom)
                }
            }
            .padding(.horizontal, 60)
            .padding(.vertical, 40)
        }
        .onAppear {
            animationScale = 1.1
        }
        .alert("Water Logged!", isPresented: $showingConfirmation) {
            Button("OK") {
                dismiss()
            }
        } message: {
            Text("Successfully logged \(selectedAmount.displayText) of water.")
        }
    }
    
    private func logWaterIntake() {
        // Create water intake record
        let waterIntake = WaterIntake(
            amount: selectedAmount.amount,
            timestamp: Date()
        )
        
        // Save to SwiftData
        modelContext.insert(waterIntake)
        
        // Show confirmation
        showingConfirmation = true
        
        // Provide haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
    }
}

// MARK: - Water Amount Card
@available(tvOS 18.0, *)
struct WaterAmountCard: View {
    let amount: TVLogWaterIntakeView.WaterAmount
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 16) {
                Image(systemName: amount.icon)
                    .font(.system(size: 40))
                    .foregroundColor(isSelected ? .white : .blue)
                
                Text(amount.displayText)
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(isSelected ? .white : .primary)
                
                if amount != .custom {
                    Text("\(amount.amount) fluid ounces")
                        .font(.subheadline)
                        .foregroundColor(isSelected ? .white.opacity(0.8) : .secondary)
                }
            }
            .frame(width: 200, height: 150)
            .background(isSelected ? Color.blue : Color(.secondarySystemBackground))
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 3)
            )
        }
        .buttonStyle(CardButtonStyle())
    }
}

// MARK: - Daily Water Progress View
@available(tvOS 18.0, *)
struct DailyWaterProgressView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var waterIntakes: [WaterIntake]
    
    private var todayIntake: Int {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        return waterIntakes
            .filter { calendar.isDate($0.timestamp, inSameDayAs: today) }
            .reduce(0) { $0 + $1.amount }
    }
    
    private var dailyGoal: Int = 64 // 8 cups of 8 oz each
    private var progress: Double {
        Double(todayIntake) / Double(dailyGoal)
    }
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Today's Progress")
                .font(.title)
                .fontWeight(.bold)
            
            VStack(spacing: 16) {
                // Progress Circle
                ZStack {
                    Circle()
                        .stroke(Color.blue.opacity(0.2), lineWidth: 12)
                        .frame(width: 200, height: 200)
                    
                    Circle()
                        .trim(from: 0, to: min(progress, 1.0))
                        .stroke(Color.blue, style: StrokeStyle(lineWidth: 12, lineCap: .round))
                        .frame(width: 200, height: 200)
                        .rotationEffect(.degrees(-90))
                        .animation(.easeInOut(duration: 1), value: progress)
                    
                    VStack(spacing: 8) {
                        Text("\(todayIntake)")
                            .font(.system(size: 36, weight: .bold, design: .rounded))
                            .foregroundColor(.blue)
                        
                        Text("oz")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Text("of \(dailyGoal)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                // Progress Stats
                HStack(spacing: 40) {
                    ProgressStatItem(
                        title: "Goal",
                        value: "\(dailyGoal) oz",
                        color: .blue
                    )
                    
                    ProgressStatItem(
                        title: "Remaining",
                        value: "\(max(0, dailyGoal - todayIntake)) oz",
                        color: .orange
                    )
                    
                    ProgressStatItem(
                        title: "Progress",
                        value: "\(Int(progress * 100))%",
                        color: .green
                    )
                }
            }
            .padding(24)
            .background(Color(.secondarySystemBackground))
            .cornerRadius(16)
        }
    }
}

// MARK: - Progress Stat Item
@available(tvOS 18.0, *)
struct ProgressStatItem: View {
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

// MARK: - Water Intake Model
@Model
class WaterIntake {
    var id: UUID
    var amount: Int
    var timestamp: Date
    
    init(amount: Int, timestamp: Date) {
        self.id = UUID()
        self.amount = amount
        self.timestamp = timestamp
    }
}

// MARK: - Button Style
@available(tvOS 18.0, *)
struct TVButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(12)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

// MARK: - Preview
#Preview {
    TVLogWaterIntakeView()
        .modelContainer(for: WaterIntake.self, inMemory: true)
} 