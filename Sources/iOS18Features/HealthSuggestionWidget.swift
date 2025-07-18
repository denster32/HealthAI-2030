import SwiftUI
import WidgetKit

@available(iOS 18.0, *)
struct HealthSuggestionWidget: Widget {
    let kind: String = "HealthSuggestionWidget"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: HealthSuggestionProvider()) { entry in
            HealthSuggestionWidgetView(entry: entry)
        }
        .configurationDisplayName("Health Suggestions")
        .description("AI-powered personalized health recommendations and reminders")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

@available(iOS 18.0, *)
struct HealthSuggestionProvider: TimelineProvider {
    func placeholder(in context: Context) -> HealthSuggestionEntry {
        HealthSuggestionEntry(
            date: Date(),
            suggestions: [
                HealthSuggestion(
                    id: "1",
                    type: .activityReminder,
                    title: "You're close to your step goal!",
                    message: "Only 1,200 more steps to reach your daily goal.",
                    priority: .medium,
                    category: .fitness,
                    actionType: .suggestion,
                    estimatedImpact: 0.7,
                    confidence: 0.85,
                    timestamp: Date(),
                    expiresAt: Date().addingTimeInterval(3600)
                )
            ],
            contextualInfo: HealthContextualInfo(
                heartRate: 72,
                stepProgress: 0.88,
                waterIntake: 48,
                timeOfDay: 14
            )
        )
    }
    
    func getSnapshot(in context: Context, completion: @escaping (HealthSuggestionEntry) -> ()) {
        let entry = HealthSuggestionEntry(
            date: Date(),
            suggestions: [
                HealthSuggestion(
                    id: "1",
                    type: .hydrationReminder,
                    title: "Stay hydrated",
                    message: "You've only had 24 oz of water today. Drink more!",
                    priority: .medium,
                    category: .nutrition,
                    actionType: .reminder,
                    estimatedImpact: 0.6,
                    confidence: 0.8,
                    timestamp: Date(),
                    expiresAt: Date().addingTimeInterval(3600)
                )
            ],
            contextualInfo: HealthContextualInfo(
                heartRate: 68,
                stepProgress: 0.65,
                waterIntake: 24,
                timeOfDay: 15
            )
        )
        completion(entry)
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<HealthSuggestionEntry>) -> ()) {
        Task {
            let currentEntry = await getCurrentSuggestionEntry()
            let timeline = Timeline(entries: [currentEntry], policy: .after(Date().addingTimeInterval(900))) // Update every 15 minutes
            completion(timeline)
        }
    }
    
    private func getCurrentSuggestionEntry() async -> HealthSuggestionEntry {
        let suggestionEngine = HealthSuggestionEngine.shared
        
        // Get current suggestions
        let suggestions = suggestionEngine.activeSuggestions.prefix(3) // Limit for widget display
        
        // Get contextual health info
        let healthManager = HealthDataManager.shared
        let heartRate = await healthManager.getLatestHeartRate()
        let stepProgress = await calculateStepProgress()
        let waterIntake = await healthManager.getTodayWaterIntake()
        
        let contextualInfo = HealthContextualInfo(
            heartRate: Int(heartRate ?? 0),
            stepProgress: stepProgress,
            waterIntake: Int(waterIntake),
            timeOfDay: Calendar.current.component(.hour, from: Date())
        )
        
        return HealthSuggestionEntry(
            date: Date(),
            suggestions: Array(suggestions),
            contextualInfo: contextualInfo
        )
    }
    
    private func calculateStepProgress() async -> Double {
        let steps = await HealthDataManager.shared.getTodaySteps() ?? 0
        return min(steps / 10000.0, 1.0)
    }
}

@available(iOS 18.0, *)
struct HealthSuggestionEntry: TimelineEntry {
    let date: Date
    let suggestions: [HealthSuggestion]
    let contextualInfo: HealthContextualInfo
}

struct HealthContextualInfo {
    let heartRate: Int
    let stepProgress: Double
    let waterIntake: Int
    let timeOfDay: Int
}

@available(iOS 18.0, *)
struct HealthSuggestionWidgetView: View {
    var entry: HealthSuggestionProvider.Entry
    @Environment(\.widgetFamily) var family
    
    var body: some View {
        switch family {
        case .systemSmall:
            SmallHealthSuggestionView(entry: entry)
        case .systemMedium:
            MediumHealthSuggestionView(entry: entry)
        case .systemLarge:
            LargeHealthSuggestionView(entry: entry)
        default:
            SmallHealthSuggestionView(entry: entry)
        }
    }
}

@available(iOS 18.0, *)
struct SmallHealthSuggestionView: View {
    let entry: HealthSuggestionEntry
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Header
            HStack {
                Image(systemName: "brain.head.profile")
                    .font(.caption)
                    .foregroundColor(.blue)
                Text("AI Health")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.blue)
                Spacer()
            }
            
            if let suggestion = entry.suggestions.first {
                VStack(alignment: .leading, spacing: 4) {
                    Text(suggestion.title)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .lineLimit(2)
                    
                    Text(suggestion.message)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .lineLimit(3)
                }
                
                // Priority indicator
                HStack {
                    Spacer()
                    PriorityIndicator(priority: suggestion.priority)
                }
            } else {
                VStack(spacing: 4) {
                    Text("All caught up!")
                        .font(.caption)
                        .fontWeight(.semibold)
                    
                    Text("No new suggestions")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

@available(iOS 18.0, *)
struct MediumHealthSuggestionView: View {
    let entry: HealthSuggestionEntry
    
    var body: some View {
        VStack(spacing: 12) {
            // Header with context
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    HStack {
                        Image(systemName: "brain.head.profile")
                            .font(.caption)
                            .foregroundColor(.blue)
                        Text("AI Health Suggestions")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.blue)
                    }
                    
                    Text(timeBasedGreeting(entry.contextualInfo.timeOfDay))
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Quick health metrics
                VStack(alignment: .trailing, spacing: 2) {
                    if entry.contextualInfo.heartRate > 0 {
                        HStack(spacing: 4) {
                            Image(systemName: "heart.fill")
                                .font(.caption2)
                                .foregroundColor(.red)
                            Text("\(entry.contextualInfo.heartRate)")
                                .font(.caption2)
                                .fontWeight(.medium)
                        }
                    }
                    
                    HStack(spacing: 4) {
                        Image(systemName: "figure.walk")
                            .font(.caption2)
                            .foregroundColor(.blue)
                        Text("\(Int(entry.contextualInfo.stepProgress * 100))%")
                            .font(.caption2)
                            .fontWeight(.medium)
                    }
                }
            }
            
            // Main suggestion
            if let primarySuggestion = entry.suggestions.first {
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Image(systemName: primarySuggestion.category.iconName)
                            .font(.title3)
                            .foregroundColor(primarySuggestion.category.color)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(primarySuggestion.title)
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .lineLimit(1)
                            
                            Text(primarySuggestion.message)
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .lineLimit(2)
                        }
                        
                        Spacer()
                        
                        PriorityIndicator(priority: primarySuggestion.priority)
                    }
                    
                    // Additional suggestions indicator
                    if entry.suggestions.count > 1 {
                        HStack {
                            Text("+\(entry.suggestions.count - 1) more suggestion\(entry.suggestions.count > 2 ? "s" : "")")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            } else {
                // No suggestions state
                VStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title)
                        .foregroundColor(.green)
                    
                    Text("All suggestions completed!")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    
                    Text("Keep up the great work with your health goals")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    private func timeBasedGreeting(_ hour: Int) -> String {
        switch hour {
        case 5..<12: return "Good morning"
        case 12..<17: return "Good afternoon"
        case 17..<22: return "Good evening"
        default: return "Good night"
        }
    }
}

@available(iOS 18.0, *)
struct LargeHealthSuggestionView: View {
    let entry: HealthSuggestionEntry
    
    var body: some View {
        VStack(spacing: 16) {
            // Header with comprehensive context
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Image(systemName: "brain.head.profile")
                            .font(.title3)
                            .foregroundColor(.blue)
                        Text("AI Health Suggestions")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.blue)
                    }
                    
                    Text("Personalized recommendations based on your health data")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Health metrics overview
                VStack(alignment: .trailing, spacing: 4) {
                    if entry.contextualInfo.heartRate > 0 {
                        HealthMetricRow(
                            icon: "heart.fill",
                            value: "\(entry.contextualInfo.heartRate) BPM",
                            color: .red
                        )
                    }
                    
                    HealthMetricRow(
                        icon: "figure.walk",
                        value: "\(Int(entry.contextualInfo.stepProgress * 100))% of goal",
                        color: .blue
                    )
                    
                    HealthMetricRow(
                        icon: "drop.fill",
                        value: "\(entry.contextualInfo.waterIntake) oz",
                        color: .cyan
                    )
                }
            }
            
            if !entry.suggestions.isEmpty {
                // Suggestions list
                VStack(spacing: 12) {
                    ForEach(Array(entry.suggestions.enumerated()), id: \.offset) { index, suggestion in
                        SuggestionCard(
                            suggestion: suggestion,
                            isPrimary: index == 0
                        )
                    }
                }
                
                // Action summary
                HStack {
                    Text("\(entry.suggestions.count) active suggestion\(entry.suggestions.count == 1 ? "" : "s")")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    let highPriorityCount = entry.suggestions.filter { $0.priority == .high }.count
                    if highPriorityCount > 0 {
                        HStack(spacing: 4) {
                            Image(systemName: "exclamationmark.circle.fill")
                                .font(.caption)
                                .foregroundColor(.red)
                            Text("\(highPriorityCount) urgent")
                                .font(.caption)
                                .foregroundColor(.red)
                                .fontWeight(.medium)
                        }
                    }
                }
                
            } else {
                // No suggestions state
                VStack(spacing: 12) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.largeTitle)
                        .foregroundColor(.green)
                    
                    Text("All caught up!")
                        .font(.title3)
                        .fontWeight(.semibold)
                    
                    Text("You're doing great with your health goals. Keep up the excellent work!")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                    
                    // Quick health overview
                    HStack(spacing: 20) {
                        HealthOverviewItem(
                            icon: "figure.walk",
                            title: "Steps",
                            progress: entry.contextualInfo.stepProgress,
                            color: .blue
                        )
                        
                        HealthOverviewItem(
                            icon: "drop.fill",
                            title: "Hydration",
                            progress: min(Double(entry.contextualInfo.waterIntake) / 64.0, 1.0),
                            color: .cyan
                        )
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

@available(iOS 18.0, *)
struct SuggestionCard: View {
    let suggestion: HealthSuggestion
    let isPrimary: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            // Category icon
            Image(systemName: suggestion.category.iconName)
                .font(isPrimary ? .title2 : .body)
                .foregroundColor(suggestion.category.color)
                .frame(width: isPrimary ? 32 : 24, height: isPrimary ? 32 : 24)
            
            // Content
            VStack(alignment: .leading, spacing: 2) {
                Text(suggestion.title)
                    .font(isPrimary ? .subheadline : .caption)
                    .fontWeight(.semibold)
                    .lineLimit(1)
                
                Text(suggestion.message)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(isPrimary ? 2 : 1)
            }
            
            Spacer()
            
            // Priority and confidence indicators
            VStack(alignment: .trailing, spacing: 2) {
                PriorityIndicator(priority: suggestion.priority)
                
                if isPrimary {
                    Text("\(Int(suggestion.confidence * 100))%")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(isPrimary ? 12 : 8)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(isPrimary ? suggestion.category.color.opacity(0.1) : Color(.systemGray6))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isPrimary ? suggestion.category.color.opacity(0.3) : Color.clear, lineWidth: 1)
        )
    }
}

@available(iOS 18.0, *)
struct PriorityIndicator: View {
    let priority: SuggestionPriority
    
    var body: some View {
        HStack(spacing: 2) {
            Image(systemName: priority.iconName)
                .font(.caption2)
                .foregroundColor(priority.color)
            Text(priority.displayName)
                .font(.caption2)
                .fontWeight(.medium)
                .foregroundColor(priority.color)
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 2)
        .background(priority.color.opacity(0.2))
        .clipShape(Capsule())
    }
}

@available(iOS 18.0, *)
struct HealthMetricRow: View {
    let icon: String
    let value: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(color)
            Text(value)
                .font(.caption)
                .fontWeight(.medium)
        }
    }
}

@available(iOS 18.0, *)
struct HealthOverviewItem: View {
    let icon: String
    let title: String
    let progress: Double
    let color: Color
    
    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)
            
            Text(title)
                .font(.caption)
                .fontWeight(.medium)
            
            ProgressView(value: progress)
                .progressViewStyle(LinearProgressViewStyle(tint: color))
                .frame(width: 40)
            
            Text("\(Int(progress * 100))%")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - Extensions

@available(iOS 18.0, *)
extension SuggestionCategory {
    var iconName: String {
        switch self {
        case .fitness: return "figure.run"
        case .nutrition: return "fork.knife"
        case .sleep: return "moon.zzz"
        case .medication: return "pills"
        case .mentalHealth: return "brain.head.profile"
        case .safety: return "shield"
        case .wellness: return "heart.circle"
        case .health: return "cross.circle"
        }
    }
    
    var color: Color {
        switch self {
        case .fitness: return .orange
        case .nutrition: return .green
        case .sleep: return .indigo
        case .medication: return .red
        case .mentalHealth: return .purple
        case .safety: return .yellow
        case .wellness: return .pink
        case .health: return .blue
        }
    }
}

@available(iOS 18.0, *)
extension SuggestionPriority {
    var iconName: String {
        switch self {
        case .high: return "exclamationmark.circle.fill"
        case .medium: return "circle.fill"
        case .low: return "circle"
        }
    }
    
    var color: Color {
        switch self {
        case .high: return .red
        case .medium: return .orange
        case .low: return .gray
        }
    }
    
    var displayName: String {
        switch self {
        case .high: return "Urgent"
        case .medium: return "Medium"
        case .low: return "Low"
        }
    }
}

// MARK: - Widget Preview

@available(iOS 18.0, *)
struct HealthSuggestionWidget_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            // Small widget with suggestion
            HealthSuggestionWidgetView(entry: HealthSuggestionEntry(
                date: Date(),
                suggestions: [
                    HealthSuggestion(
                        id: "1",
                        type: .activityReminder,
                        title: "Almost there!",
                        message: "Just 800 more steps to reach your goal",
                        priority: .medium,
                        category: .fitness,
                        actionType: .suggestion,
                        estimatedImpact: 0.7,
                        confidence: 0.85,
                        timestamp: Date(),
                        expiresAt: Date().addingTimeInterval(3600)
                    )
                ],
                contextualInfo: HealthContextualInfo(
                    heartRate: 75,
                    stepProgress: 0.92,
                    waterIntake: 45,
                    timeOfDay: 16
                )
            ))
            .previewContext(WidgetPreviewContext(family: .systemSmall))
            .previewDisplayName("Small - Active Suggestion")
            
            // Medium widget with multiple suggestions
            HealthSuggestionWidgetView(entry: HealthSuggestionEntry(
                date: Date(),
                suggestions: [
                    HealthSuggestion(
                        id: "1",
                        type: .hydrationReminder,
                        title: "Stay hydrated",
                        message: "You're behind on your water intake today",
                        priority: .medium,
                        category: .nutrition,
                        actionType: .reminder,
                        estimatedImpact: 0.6,
                        confidence: 0.8,
                        timestamp: Date(),
                        expiresAt: Date().addingTimeInterval(3600)
                    ),
                    HealthSuggestion(
                        id: "2",
                        type: .stressManagement,
                        title: "Take a breathing break",
                        message: "High stress detected",
                        priority: .high,
                        category: .mentalHealth,
                        actionType: .action,
                        estimatedImpact: 0.8,
                        confidence: 0.9,
                        timestamp: Date(),
                        expiresAt: Date().addingTimeInterval(1800)
                    )
                ],
                contextualInfo: HealthContextualInfo(
                    heartRate: 88,
                    stepProgress: 0.65,
                    waterIntake: 20,
                    timeOfDay: 14
                )
            ))
            .previewContext(WidgetPreviewContext(family: .systemMedium))
            .previewDisplayName("Medium - Multiple Suggestions")
            
            // Large widget with no suggestions
            HealthSuggestionWidgetView(entry: HealthSuggestionEntry(
                date: Date(),
                suggestions: [],
                contextualInfo: HealthContextualInfo(
                    heartRate: 68,
                    stepProgress: 1.0,
                    waterIntake: 64,
                    timeOfDay: 18
                )
            ))
            .previewContext(WidgetPreviewContext(family: .systemLarge))
            .previewDisplayName("Large - No Suggestions")
        }
    }
}