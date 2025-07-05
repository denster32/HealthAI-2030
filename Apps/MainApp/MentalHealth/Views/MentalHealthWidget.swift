import WidgetKit
import SwiftUI
import HealthKit

// MARK: - Mental Health Widget

public struct MentalHealthWidget: Widget {
    let kind: String = "MentalHealthWidget"
    
    public init() {}
    
    public var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: MentalHealthTimelineProvider()) { entry in
            MentalHealthWidgetView(entry: entry)
        }
        .configurationDisplayName(Text("Mental Health", comment: "Widget display name for mental health"))
        .description(Text("Track your mental health score and mindfulness progress.", comment: "Widget description for mental health"))
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

struct MentalHealthTimelineProvider: TimelineProvider {
    func placeholder(in context: Context) -> MentalHealthEntry {
        MentalHealthEntry(date: Date(), score: 0.75, stressLevel: .moderate, mindfulnessMinutes: 15)
    }
    
    func getSnapshot(in context: Context, completion: @escaping (MentalHealthEntry) -> Void) {
        let entry = MentalHealthEntry(date: Date(), score: 0.82, stressLevel: .low, mindfulnessMinutes: 20)
        completion(entry)
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<MentalHealthEntry>) -> Void) {
        let currentDate = Date()
        guard let refreshDate = Calendar.current.date(byAdding: .minute, value: 15, to: currentDate) else {
            let fallbackDate = currentDate.addingTimeInterval(15 * 60)
            let entry = makeEntry()
            let timeline = Timeline(entries: [entry], policy: .after(fallbackDate))
            completion(timeline)
            return
        }
        let entry = makeEntry()
        let timeline = Timeline(entries: [entry], policy: .after(refreshDate))
        completion(timeline)
    }
    
    private func makeEntry() -> MentalHealthEntry {
        if #available(macOS 14.0, *) {
            let score = MentalHealthManager.shared.mentalHealthScore
            let stress = MentalHealthManager.shared.stressLevel
            let minutes = Int(MentalHealthManager.shared.mindfulnessSessions.reduce(0) { $0 + $1.duration } / 60)
            return MentalHealthEntry(date: Date(), score: score, stressLevel: stress, mindfulnessMinutes: minutes)
        } else {
            return MentalHealthEntry(date: Date(), score: 0.0, stressLevel: .low, mindfulnessMinutes: 0)
        }
    }
}

public struct MentalHealthEntry: TimelineEntry {
    public let date: Date
    public let score: Double
    public let stressLevel: StressLevel
    public let mindfulnessMinutes: Int
}

struct MentalHealthWidgetView: View {
    let entry: MentalHealthEntry
    @Environment(\.widgetFamily) var family
    
    var body: some View {
        switch family {
        case .systemSmall:
            MentalHealthSmallView(entry: entry)
        case .systemMedium:
            MentalHealthMediumView(entry: entry)
        default:
            MentalHealthSmallView(entry: entry)
        }
    }
}

struct MentalHealthSmallView: View {
    let entry: MentalHealthEntry
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: "brain")
                    .foregroundColor(.purple)
                    .accessibilityLabel(Text("Brain icon"))
                Text(LocalizedStringKey("Mental Health"))
                    .font(.caption)
                    .fontWeight(.medium)
                    .accessibilityLabel(Text("Mental Health Widget Title", comment: "Accessibility label for the mental health widget title"))
                Spacer()
            }
            
            Spacer()
            
            VStack(spacing: 4) {
                Text("\(Int(entry.score * 100))")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.purple)
                    .accessibilityValue(Text("\(Int(entry.score * 100)) percent", comment: "Accessibility value for mental health score"))
                
                Text(LocalizedStringKey("Score"))
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .accessibilityLabel(Text("Mental Health Score Label", comment: "Accessibility label for mental health score"))
            }
            
            Spacer()
            
            HStack {
                Label(LocalizedStringKey("\(entry.mindfulnessMinutes)m"), systemImage: "leaf")
                    .font(.caption2)
                    .foregroundColor(.green)
                    .accessibilityLabel(Text("\(entry.mindfulnessMinutes) minutes of mindfulness", comment: "Accessibility label for mindfulness minutes"))
                
                Spacer()
                
                Text(LocalizedStringKey(entry.stressLevel.displayName))
                    .font(.caption2)
                    .foregroundColor(stressColor)
                    .accessibilityLabel(Text("Stress level: \(entry.stressLevel.displayName)", comment: "Accessibility label for stress level"))
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Text("Mental health score: \(Int(entry.score * 100)), stress: \(entry.stressLevel.displayName), mindfulness: \(entry.mindfulnessMinutes) minutes"))
    }
    
    private var stressColor: Color {
        switch entry.stressLevel {
        case .low: return .green
        case .moderate: return .yellow
        case .high: return .orange
        case .severe: return .red
        }
    }
}

struct MentalHealthMediumView: View {
    let entry: MentalHealthEntry
    
    var body: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "brain")
                        .foregroundColor(.purple)
                        .accessibilityLabel(Text("Brain icon"))
                    Text(LocalizedStringKey("Mental Health"))
                        .font(.headline)
                        .fontWeight(.semibold)
                        .accessibilityLabel(Text("Mental Health Widget Title", comment: "Accessibility label for the mental health widget title"))
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(LocalizedStringKey("Overall Score"))
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .accessibilityLabel(Text("Overall Mental Health Score Label", comment: "Accessibility label for overall mental health score"))
                    Text("\(Int(entry.score * 100))")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.purple)
                        .accessibilityValue(Text("\(Int(entry.score * 100)) percent", comment: "Accessibility value for overall mental health score"))
                }
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 12) {
                HStack {
                    Image(systemName: "leaf")
                        .foregroundColor(.green)
                    Text(LocalizedStringKey("\(entry.mindfulnessMinutes)m"))
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .accessibilityLabel(Text("\(entry.mindfulnessMinutes) minutes of mindfulness", comment: "Accessibility label for mindfulness minutes"))
                }
                
                HStack {
                    Image(systemName: "exclamationmark.triangle")
                        .foregroundColor(stressColor)
                    Text(LocalizedStringKey(entry.stressLevel.displayName))
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .accessibilityLabel(Text("Stress level: \(entry.stressLevel.displayName)", comment: "Accessibility label for stress level"))
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Text("Mental health score: \(Int(entry.score * 100)), stress: \(entry.stressLevel.displayName), mindfulness: \(entry.mindfulnessMinutes) minutes"))
    }
    
    private var stressColor: Color {
        switch entry.stressLevel {
        case .low: return .green
        case .moderate: return .yellow
        case .high: return .orange
        case .severe: return .red
        }
    }
}