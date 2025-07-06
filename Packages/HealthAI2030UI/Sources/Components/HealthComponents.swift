import SwiftUI
import HealthAI2030DesignSystem

// MARK: - HeartRateDisplay
public struct HeartRateDisplay: View {
    @State private var scale: CGFloat = 1.0
    let heartRate: Int

    public var body: some View {
        Text("❤️ \(heartRate) BPM")
            .font(.largeTitle)
            .scaleEffect(scale)
            .onAppear {
                let baseAnimation = Animation.easeInOut(duration: 0.5)
                let repeated = baseAnimation.repeatForever(autoreverses: true)
                withAnimation(repeated) {
                    scale = 1.1
                }
            }
            .accessibilityLabel(Text("Heart Rate: \(heartRate) beats per minute"))
    }
}

// MARK: - SleepStageIndicator
public struct SleepStageIndicator: View {
    let stage: String

    public var body: some View {
        HStack {
            Image(systemName: "moon.zzz.fill")
            Text(stage)
        }
        .font(HealthAIDesignSystem.Typography.headline)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Text("Sleep Stage: \(stage)"))
    }
}

// MARK: - ActivityRing
public struct ActivityRing: View {
    let progress: Double
    let color: Color
    let lineWidth: CGFloat = 20.0

    public var body: some View {
        ZStack {
            Circle()
                .stroke(lineWidth: lineWidth)
                .opacity(0.3)
                .foregroundColor(color)
            
            Circle()
                .trim(from: 0.0, to: CGFloat(min(self.progress, 1.0)))
                .stroke(style: StrokeStyle(lineWidth: lineWidth, lineCap: .round, lineJoin: .round))
                .foregroundColor(color)
                .rotationEffect(Angle(degrees: 270.0))
                .animation(.linear, value: progress)
        }
        .frame(width: 150, height: 150)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text("Activity Ring: \(Int(progress * 100)) percent complete"))
    }
}

// MARK: - HealthMetricCard
public struct HealthMetricCard: View {
    let title: String
    let value: String
    let trend: String

    public var body: some View {
        HealthAICard {
            VStack(alignment: .leading) {
                Text(title)
                    .font(HealthAIDesignSystem.Typography.headline)
                Text(value)
                    .font(HealthAIDesignSystem.Typography.title)
                Text(trend)
                    .font(HealthAIDesignSystem.Typography.subheadline)
                    .foregroundColor(HealthAIDesignSystem.Color.textSecondary)
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel(Text("\(title): \(value), trend: \(trend)"))
        }
    }
}

// MARK: - MoodSelector
public struct MoodSelector: View {
    @Binding var selectedMood: String
    let moods = ["😊", "🙂", "😐", "😟", "😢"]

    public var body: some View {
        HStack {
            ForEach(moods, id: \.self) { mood in
                Button(action: {
                    self.selectedMood = mood
                    // Haptic feedback
                    UINotificationFeedbackGenerator().notificationOccurred(.success)
                }) {
                    Text(mood)
                        .font(.largeTitle)
                        .padding(8)
                        .background(selectedMood == mood ? HealthAIDesignSystem.Color.surface : .clear)
                        .cornerRadius(HealthAIDesignSystem.Layout.cornerRadius)
                }
                .accessibilityLabel(Text(moodAccessibilityLabel(mood)))
            }
        }
    }
    
    private func moodAccessibilityLabel(_ mood: String) -> String {
        switch mood {
        case "😊": return "Happy"
        case "🙂": return "Pleased"
        case "😐": return "Neutral"
        case "😟": return "Worried"
        case "😢": return "Sad"
        default: return ""
        }
    }
}

// MARK: - WaterIntakeTracker
public struct WaterIntakeTracker: View {
    let intake: Int
    let goal: Int

    public var body: some View {
        VStack {
            HStack {
                ForEach(0..<goal, id: \.self) { index in
                    Image(systemName: index < intake ? "drop.fill" : "drop")
                        .foregroundColor(HealthAIDesignSystem.Color.infoBlue)
                }
            }
            Text("\(intake) / \(goal) glasses")
                .font(HealthAIDesignSystem.Typography.caption)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text("Water Intake: \(intake) out of \(goal) glasses"))
    }
}
