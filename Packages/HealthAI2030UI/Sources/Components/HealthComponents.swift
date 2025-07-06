import SwiftUI
import HealthAI2030DesignSystem

// MARK: - HeartRateDisplay
public struct HeartRateDisplay: View {
    @State private var scale: CGFloat = 1.0
    let heartRate: Int
    let showAnimation: Bool
    let size: HeartRateSize
    
    public enum HeartRateSize {
        case small, medium, large
        
        var fontSize: Font {
            switch self {
            case .small: return .title2
            case .medium: return .largeTitle
            case .large: return .system(size: 48, weight: .bold, design: .rounded)
            }
        }
        
        var iconSize: CGFloat {
            switch self {
            case .small: return 16
            case .medium: return 24
            case .large: return 32
            }
        }
    }
    
    public init(heartRate: Int, showAnimation: Bool = true, size: HeartRateSize = .medium) {
        self.heartRate = heartRate
        self.showAnimation = showAnimation
        self.size = size
    }

    public var body: some View {
        HStack(spacing: HealthAIDesignSystem.Spacing.small) {
            Image(systemName: "heart.fill")
                .font(.system(size: size.iconSize))
                .foregroundColor(.red)
                .scaleEffect(showAnimation ? scale : 1.0)
                .accessibilityHidden(true)
            
            Text("\(heartRate)")
                .font(size.fontSize)
                .fontWeight(.bold)
                .foregroundColor(.red)
            
            Text("BPM")
                .font(HealthAIDesignSystem.Typography.caption)
                .foregroundColor(HealthAIDesignSystem.Color.textSecondary)
        }
        .onAppear {
            if showAnimation {
                let baseAnimation = Animation.easeInOut(duration: 0.5)
                let repeated = baseAnimation.repeatForever(autoreverses: true)
                withAnimation(repeated) {
                    scale = 1.1
                }
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Text("Heart Rate: \(heartRate) beats per minute"))
        .accessibilityAddTraits(.updatesFrequently)
    }
}

// MARK: - SleepStageIndicator
public struct SleepStageIndicator: View {
    let stage: String
    let duration: TimeInterval?
    let showIcon: Bool
    
    public init(stage: String, duration: TimeInterval? = nil, showIcon: Bool = true) {
        self.stage = stage
        self.duration = duration
        self.showIcon = showIcon
    }

    public var body: some View {
        HStack(spacing: HealthAIDesignSystem.Spacing.small) {
            if showIcon {
                Image(systemName: stageIcon)
                    .foregroundColor(stageColor)
                    .accessibilityHidden(true)
            }
            
            VStack(alignment: .leading, spacing: HealthAIDesignSystem.Spacing.extraSmall) {
                Text(stage)
                    .font(HealthAIDesignSystem.Typography.headline)
                    .fontWeight(.medium)
                    .foregroundColor(HealthAIDesignSystem.Color.textPrimary)
                
                if let duration = duration {
                    Text(formatDuration(duration))
                        .font(HealthAIDesignSystem.Typography.caption)
                        .foregroundColor(HealthAIDesignSystem.Color.textSecondary)
                }
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Text("Sleep Stage: \(stage)\(durationText)"))
    }
    
    private var stageIcon: String {
        switch stage.lowercased() {
        case "awake": return "eye.fill"
        case "rem": return "brain.head.profile"
        case "light": return "moon.fill"
        case "deep": return "moon.zzz.fill"
        default: return "moon.zzz.fill"
        }
    }
    
    private var stageColor: Color {
        switch stage.lowercased() {
        case "awake": return .orange
        case "rem": return .purple
        case "light": return .blue
        case "deep": return .indigo
        default: return .blue
        }
    }
    
    private var durationText: String {
        guard let duration = duration else { return "" }
        return ", duration: \(formatDuration(duration))"
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let hours = Int(duration) / 3600
        let minutes = Int(duration) % 3600 / 60
        return "\(hours)h \(minutes)m"
    }
}

// MARK: - ActivityRing
public struct ActivityRing: View {
    let progress: Double
    let color: Color
    let lineWidth: CGFloat
    let size: ActivityRingSize
    let showPercentage: Bool
    
    public enum ActivityRingSize {
        case small, medium, large
        
        var diameter: CGFloat {
            switch self {
            case .small: return 80
            case .medium: return 120
            case .large: return 150
            }
        }
        
        var fontSize: Font {
            switch self {
            case .small: return .caption
            case .medium: return .subheadline
            case .large: return .headline
            }
        }
    }
    
    public init(progress: Double, color: Color = .blue, lineWidth: CGFloat = 20.0, size: ActivityRingSize = .medium, showPercentage: Bool = true) {
        self.progress = progress
        self.color = color
        self.lineWidth = lineWidth
        self.size = size
        self.showPercentage = showPercentage
    }

    public var body: some View {
        ZStack {
            // Background ring
            Circle()
                .stroke(lineWidth: lineWidth)
                .opacity(0.3)
                .foregroundColor(color)
            
            // Progress ring
            Circle()
                .trim(from: 0.0, to: CGFloat(min(self.progress, 1.0)))
                .stroke(style: StrokeStyle(lineWidth: lineWidth, lineCap: .round, lineJoin: .round))
                .foregroundColor(color)
                .rotationEffect(Angle(degrees: 270.0))
                .animation(.easeInOut(duration: 1.0), value: progress)
            
            // Center content
            if showPercentage {
                VStack(spacing: HealthAIDesignSystem.Spacing.extraSmall) {
                    Text("\(Int(progress * 100))")
                        .font(size.fontSize)
                        .fontWeight(.bold)
                        .foregroundColor(color)
                    
                    Text("%")
                        .font(HealthAIDesignSystem.Typography.caption)
                        .foregroundColor(HealthAIDesignSystem.Color.textSecondary)
                }
            }
        }
        .frame(width: size.diameter, height: size.diameter)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text("Activity Ring: \(Int(progress * 100)) percent complete"))
        .accessibilityValue(Text("\(Int(progress * 100)) percent"))
    }
}

// MARK: - HealthMetricCard
public struct HealthMetricCard: View {
    let title: String
    let value: String
    let trend: String?
    let icon: String?
    let color: Color?
    let subtitle: String?
    
    public init(title: String, value: String, trend: String? = nil, icon: String? = nil, color: Color? = nil, subtitle: String? = nil) {
        self.title = title
        self.value = value
        self.trend = trend
        self.icon = icon
        self.color = color
        self.subtitle = subtitle
    }

    public var body: some View {
        HealthAICard {
            VStack(alignment: .leading, spacing: HealthAIDesignSystem.Spacing.small) {
                // Header
                HStack {
                    if let icon = icon {
                        Image(systemName: icon)
                            .foregroundColor(color ?? HealthAIDesignSystem.Color.healthPrimary)
                            .font(.title2)
                            .accessibilityHidden(true)
                    }
                    
                    Text(title)
                        .font(HealthAIDesignSystem.Typography.headline)
                        .fontWeight(.medium)
                        .foregroundColor(HealthAIDesignSystem.Color.textPrimary)
                    
                    Spacer()
                    
                    if let trend = trend {
                        Text(trend)
                            .font(HealthAIDesignSystem.Typography.caption)
                            .foregroundColor(HealthAIDesignSystem.Color.textSecondary)
                    }
                }
                
                // Value
                Text(value)
                    .font(HealthAIDesignSystem.Typography.title)
                    .fontWeight(.bold)
                    .foregroundColor(color ?? HealthAIDesignSystem.Color.textPrimary)
                
                // Subtitle
                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(HealthAIDesignSystem.Typography.caption)
                        .foregroundColor(HealthAIDesignSystem.Color.textSecondary)
                }
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel(Text("\(title): \(value)\(trendText)"))
        }
    }
    
    private var trendText: String {
        guard let trend = trend else { return "" }
        return ", trend: \(trend)"
    }
}

// MARK: - MoodSelector
public struct MoodSelector: View {
    @Binding var selectedMood: String
    let moods: [MoodOption]
    let showLabels: Bool
    
    public struct MoodOption {
        let emoji: String
        let label: String
        let color: Color
        
        public init(emoji: String, label: String, color: Color) {
            self.emoji = emoji
            self.label = label
            self.color = color
        }
    }
    
    public init(selectedMood: Binding<String>, moods: [MoodOption]? = nil, showLabels: Bool = false) {
        self._selectedMood = selectedMood
        self.moods = moods ?? defaultMoods
        self.showLabels = showLabels
    }

    public var body: some View {
        VStack(spacing: HealthAIDesignSystem.Spacing.small) {
            HStack(spacing: HealthAIDesignSystem.Spacing.medium) {
                ForEach(moods, id: \.emoji) { mood in
                    Button(action: {
                        self.selectedMood = mood.emoji
                        // Haptic feedback
                        UINotificationFeedbackGenerator().notificationOccurred(.success)
                    }) {
                        VStack(spacing: HealthAIDesignSystem.Spacing.extraSmall) {
                            Text(mood.emoji)
                                .font(.system(size: 32))
                                .padding(8)
                                .background(selectedMood == mood.emoji ? mood.color.opacity(0.2) : Color.clear)
                                .cornerRadius(HealthAIDesignSystem.Layout.cornerRadius)
                            
                            if showLabels {
                                Text(mood.label)
                                    .font(HealthAIDesignSystem.Typography.caption)
                                    .foregroundColor(HealthAIDesignSystem.Color.textSecondary)
                            }
                        }
                    }
                    .accessibilityLabel(Text(mood.label))
                    .accessibilityAddTraits(selectedMood == mood.emoji ? .isSelected : [])
                }
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel(Text("Mood Selector"))
    }
    
    private static var defaultMoods: [MoodOption] {
        [
            MoodOption(emoji: "😊", label: "Happy", color: .green),
            MoodOption(emoji: "🙂", label: "Pleased", color: .blue),
            MoodOption(emoji: "😐", label: "Neutral", color: .gray),
            MoodOption(emoji: "😟", label: "Worried", color: .orange),
            MoodOption(emoji: "😢", label: "Sad", color: .red)
        ]
    }
}

// MARK: - WaterIntakeTracker
public struct WaterIntakeTracker: View {
    let intake: Int
    let goal: Int
    let unit: String
    let showProgress: Bool
    
    public init(intake: Int, goal: Int, unit: String = "glasses", showProgress: Bool = true) {
        self.intake = intake
        self.goal = goal
        self.unit = unit
        self.showProgress = showProgress
    }

    public var body: some View {
        VStack(spacing: HealthAIDesignSystem.Spacing.small) {
            if showProgress {
                // Visual progress
                HStack(spacing: HealthAIDesignSystem.Spacing.extraSmall) {
                    ForEach(0..<goal, id: \.self) { index in
                        Image(systemName: index < intake ? "drop.fill" : "drop")
                            .foregroundColor(HealthAIDesignSystem.Color.infoBlue)
                            .font(.title3)
                    }
                }
            }
            
            // Text display
            HStack {
                Text("\(intake)")
                    .font(HealthAIDesignSystem.Typography.title2)
                    .fontWeight(.bold)
                    .foregroundColor(HealthAIDesignSystem.Color.infoBlue)
                
                Text("/ \(goal) \(unit)")
                    .font(HealthAIDesignSystem.Typography.caption)
                    .foregroundColor(HealthAIDesignSystem.Color.textSecondary)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text("Water Intake: \(intake) out of \(goal) \(unit)"))
        .accessibilityValue(Text("\(Int((Double(intake) / Double(goal)) * 100)) percent complete"))
    }
}

// MARK: - HealthTrendIndicator
public struct HealthTrendIndicator: View {
    let trend: HealthTrend
    let value: String
    let showArrow: Bool
    
    public enum HealthTrend {
        case improving, declining, stable
        
        var color: Color {
            switch self {
            case .improving: return HealthAIDesignSystem.Color.successGreen
            case .declining: return HealthAIDesignSystem.Color.warningRed
            case .stable: return HealthAIDesignSystem.Color.textSecondary
            }
        }
        
        var icon: String {
            switch self {
            case .improving: return "arrow.up.right"
            case .declining: return "arrow.down.right"
            case .stable: return "arrow.right"
            }
        }
        
        var label: String {
            switch self {
            case .improving: return "Improving"
            case .declining: return "Declining"
            case .stable: return "Stable"
            }
        }
    }
    
    public init(trend: HealthTrend, value: String, showArrow: Bool = true) {
        self.trend = trend
        self.value = value
        self.showArrow = showArrow
    }
    
    public var body: some View {
        HStack(spacing: HealthAIDesignSystem.Spacing.extraSmall) {
            if showArrow {
                Image(systemName: trend.icon)
                    .font(HealthAIDesignSystem.Typography.caption)
                    .foregroundColor(trend.color)
                    .accessibilityHidden(true)
            }
            
            Text(value)
                .font(HealthAIDesignSystem.Typography.caption)
                .foregroundColor(trend.color)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Text("Trend: \(trend.label), \(value)"))
    }
}

// MARK: - HealthScoreRing
public struct HealthScoreRing: View {
    let score: Double
    let size: HealthScoreSize
    let showLabel: Bool
    
    public enum HealthScoreSize {
        case small, medium, large
        
        var diameter: CGFloat {
            switch self {
            case .small: return 60
            case .medium: return 100
            case .large: return 150
            }
        }
        
        var lineWidth: CGFloat {
            switch self {
            case .small: return 4
            case .medium: return 8
            case .large: return 12
            }
        }
        
        var fontSize: Font {
            switch self {
            case .small: return .caption
            case .medium: return .subheadline
            case .large: return .title2
            }
        }
    }
    
    public init(score: Double, size: HealthScoreSize = .medium, showLabel: Bool = true) {
        self.score = score
        self.size = size
        self.showLabel = showLabel
    }
    
    public var body: some View {
        ZStack {
            // Background ring
            Circle()
                .stroke(lineWidth: size.lineWidth)
                .opacity(0.2)
                .foregroundColor(scoreColor)
            
            // Score ring
            Circle()
                .trim(from: 0.0, to: CGFloat(min(self.score, 1.0)))
                .stroke(style: StrokeStyle(lineWidth: size.lineWidth, lineCap: .round, lineJoin: .round))
                .foregroundColor(scoreColor)
                .rotationEffect(Angle(degrees: 270.0))
                .animation(.easeInOut(duration: 1.0), value: score)
            
            // Center content
            if showLabel {
                VStack(spacing: HealthAIDesignSystem.Spacing.extraSmall) {
                    Text("\(Int(score * 100))")
                        .font(size.fontSize)
                        .fontWeight(.bold)
                        .foregroundColor(scoreColor)
                    
                    Text("Score")
                        .font(HealthAIDesignSystem.Typography.caption)
                        .foregroundColor(HealthAIDesignSystem.Color.textSecondary)
                }
            }
        }
        .frame(width: size.diameter, height: size.diameter)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text("Health Score: \(Int(score * 100)) out of 100"))
        .accessibilityValue(Text("\(Int(score * 100)) percent"))
    }
    
    private var scoreColor: Color {
        if score >= 0.8 { return HealthAIDesignSystem.Color.successGreen }
        if score >= 0.6 { return .orange }
        return HealthAIDesignSystem.Color.warningRed
    }
}
