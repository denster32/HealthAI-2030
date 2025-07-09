import SwiftUI
import WidgetKit

/// Advanced Health Widget System
@available(iOS 14.0, *)
public struct AdvancedHealthWidgets {
    
    // MARK: - Daily Health Summary Widget
    public struct DailyHealthSummaryWidget: Widget {
        public let kind: String = "DailyHealthSummaryWidget"
        
        public var body: some WidgetConfiguration {
            StaticConfiguration(kind: kind, provider: DailyHealthSummaryProvider()) { entry in
                DailyHealthSummaryWidgetView(entry: entry)
            }
            .configurationDisplayName("Daily Health Summary")
            .description("View your daily health overview")
            .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
        }
    }
    
    // MARK: - Quick Health Insights Widget
    public struct QuickHealthInsightsWidget: Widget {
        public let kind: String = "QuickHealthInsightsWidget"
        
        public var body: some WidgetConfiguration {
            StaticConfiguration(kind: kind, provider: QuickHealthInsightsProvider()) { entry in
                QuickHealthInsightsWidgetView(entry: entry)
            }
            .configurationDisplayName("Quick Health Insights")
            .description("Get quick health insights")
            .supportedFamilies([.systemSmall, .systemMedium])
        }
    }
    
    // MARK: - Goal Progress Tracking Widget
    public struct GoalProgressTrackingWidget: Widget {
        public let kind: String = "GoalProgressTrackingWidget"
        
        public var body: some WidgetConfiguration {
            StaticConfiguration(kind: kind, provider: GoalProgressProvider()) { entry in
                GoalProgressTrackingWidgetView(entry: entry)
            }
            .configurationDisplayName("Goal Progress")
            .description("Track your health goals")
            .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
        }
    }
    
    // MARK: - Emergency Health Alerts Widget
    public struct EmergencyHealthAlertsWidget: Widget {
        public let kind: String = "EmergencyHealthAlertsWidget"
        
        public var body: some WidgetConfiguration {
            StaticConfiguration(kind: kind, provider: EmergencyAlertsProvider()) { entry in
                EmergencyHealthAlertsWidgetView(entry: entry)
            }
            .configurationDisplayName("Emergency Health Alerts")
            .description("Monitor critical health alerts")
            .supportedFamilies([.systemSmall, .systemMedium])
        }
    }
    
    // MARK: - Medication Reminders Widget
    public struct MedicationRemindersWidget: Widget {
        public let kind: String = "MedicationRemindersWidget"
        
        public var body: some WidgetConfiguration {
            StaticConfiguration(kind: kind, provider: MedicationRemindersProvider()) { entry in
                MedicationRemindersWidgetView(entry: entry)
            }
            .configurationDisplayName("Medication Reminders")
            .description("Track your medication schedule")
            .supportedFamilies([.systemSmall, .systemMedium])
        }
    }
}

// MARK: - Widget Entry Models

@available(iOS 14.0, *)
public struct DailyHealthSummaryEntry: TimelineEntry {
    public let date: Date
    public let steps: Int
    public let calories: Int
    public let heartRate: Int
    public let sleepHours: Double
    public let waterIntake: Double
    public let mood: String
}

@available(iOS 14.0, *)
public struct QuickHealthInsightsEntry: TimelineEntry {
    public let date: Date
    public let insights: [HealthInsight]
    public let riskLevel: RiskLevel
    public let recommendations: [String]
}

@available(iOS 14.0, *)
public struct GoalProgressEntry: TimelineEntry {
    public let date: Date
    public let goals: [HealthGoal]
    public let overallProgress: Double
}

@available(iOS 14.0, *)
public struct EmergencyAlertsEntry: TimelineEntry {
    public let date: Date
    public let alerts: [HealthAlert]
    public let criticalCount: Int
}

@available(iOS 14.0, *)
public struct MedicationRemindersEntry: TimelineEntry {
    public let date: Date
    public let medications: [MedicationReminder]
    public let nextDose: Date?
}

// MARK: - Supporting Types

@available(iOS 14.0, *)
public struct HealthInsight: Identifiable {
    public let id = UUID()
    public let title: String
    public let description: String
    public let type: InsightType
    public let severity: Severity
    
    public enum InsightType: String { case sleep, exercise, nutrition, stress, heart, other }
    public enum Severity: String { case low, medium, high, critical }
}

@available(iOS 14.0, *)
public enum RiskLevel: String { case low, moderate, high, critical }

@available(iOS 14.0, *)
public struct HealthGoal: Identifiable {
    public let id = UUID()
    public let name: String
    public let target: Double
    public let current: Double
    public let unit: String
    public let type: GoalType
    
    public enum GoalType: String { case steps, calories, sleep, water, exercise, other }
}

@available(iOS 14.0, *)
public struct HealthAlert: Identifiable {
    public let id = UUID()
    public let title: String
    public let message: String
    public let severity: AlertSeverity
    public let timestamp: Date
    
    public enum AlertSeverity: String { case info, warning, critical }
}

@available(iOS 14.0, *)
public struct MedicationReminder: Identifiable {
    public let id = UUID()
    public let name: String
    public let dosage: String
    public let time: Date
    public let taken: Bool
}

// MARK: - Widget Providers

@available(iOS 14.0, *)
public struct DailyHealthSummaryProvider: TimelineProvider {
    public func placeholder(in context: Context) -> DailyHealthSummaryEntry {
        DailyHealthSummaryEntry(date: Date(), steps: 8000, calories: 1800, heartRate: 72, sleepHours: 7.5, waterIntake: 2.0, mood: "Good")
    }
    
    public func getSnapshot(in context: Context, completion: @escaping (DailyHealthSummaryEntry) -> ()) {
        completion(DailyHealthSummaryEntry(date: Date(), steps: 8000, calories: 1800, heartRate: 72, sleepHours: 7.5, waterIntake: 2.0, mood: "Good"))
    }
    
    public func getTimeline(in context: Context, completion: @escaping (Timeline<DailyHealthSummaryEntry>) -> ()) {
        let entry = DailyHealthSummaryEntry(date: Date(), steps: 8000, calories: 1800, heartRate: 72, sleepHours: 7.5, waterIntake: 2.0, mood: "Good")
        let timeline = Timeline(entries: [entry], policy: .atEnd)
        completion(timeline)
    }
}

@available(iOS 14.0, *)
public struct QuickHealthInsightsProvider: TimelineProvider {
    public func placeholder(in context: Context) -> QuickHealthInsightsEntry {
        QuickHealthInsightsEntry(date: Date(), insights: [], riskLevel: .low, recommendations: [])
    }
    
    public func getSnapshot(in context: Context, completion: @escaping (QuickHealthInsightsEntry) -> ()) {
        let insights = [HealthInsight(title: "Sleep Quality", description: "Your sleep quality improved", type: .sleep, severity: .low)]
        completion(QuickHealthInsightsEntry(date: Date(), insights: insights, riskLevel: .low, recommendations: ["Continue good sleep habits"]))
    }
    
    public func getTimeline(in context: Context, completion: @escaping (Timeline<QuickHealthInsightsEntry>) -> ()) {
        let insights = [HealthInsight(title: "Sleep Quality", description: "Your sleep quality improved", type: .sleep, severity: .low)]
        let entry = QuickHealthInsightsEntry(date: Date(), insights: insights, riskLevel: .low, recommendations: ["Continue good sleep habits"])
        let timeline = Timeline(entries: [entry], policy: .atEnd)
        completion(timeline)
    }
}

@available(iOS 14.0, *)
public struct GoalProgressProvider: TimelineProvider {
    public func placeholder(in context: Context) -> GoalProgressEntry {
        GoalProgressEntry(date: Date(), goals: [], overallProgress: 0.0)
    }
    
    public func getSnapshot(in context: Context, completion: @escaping (GoalProgressEntry) -> ()) {
        let goals = [HealthGoal(name: "Daily Steps", target: 10000, current: 8000, unit: "steps", type: .steps)]
        completion(GoalProgressEntry(date: Date(), goals: goals, overallProgress: 0.8))
    }
    
    public func getTimeline(in context: Context, completion: @escaping (Timeline<GoalProgressEntry>) -> ()) {
        let goals = [HealthGoal(name: "Daily Steps", target: 10000, current: 8000, unit: "steps", type: .steps)]
        let entry = GoalProgressEntry(date: Date(), goals: goals, overallProgress: 0.8)
        let timeline = Timeline(entries: [entry], policy: .atEnd)
        completion(timeline)
    }
}

@available(iOS 14.0, *)
public struct EmergencyAlertsProvider: TimelineProvider {
    public func placeholder(in context: Context) -> EmergencyAlertsEntry {
        EmergencyAlertsEntry(date: Date(), alerts: [], criticalCount: 0)
    }
    
    public func getSnapshot(in context: Context, completion: @escaping (EmergencyAlertsEntry) -> ()) {
        let alerts = [HealthAlert(title: "High Heart Rate", message: "Heart rate above normal", severity: .warning, timestamp: Date())]
        completion(EmergencyAlertsEntry(date: Date(), alerts: alerts, criticalCount: 0))
    }
    
    public func getTimeline(in context: Context, completion: @escaping (Timeline<EmergencyAlertsEntry>) -> ()) {
        let alerts = [HealthAlert(title: "High Heart Rate", message: "Heart rate above normal", severity: .warning, timestamp: Date())]
        let entry = EmergencyAlertsEntry(date: Date(), alerts: alerts, criticalCount: 0)
        let timeline = Timeline(entries: [entry], policy: .atEnd)
        completion(timeline)
    }
}

@available(iOS 14.0, *)
public struct MedicationRemindersProvider: TimelineProvider {
    public func placeholder(in context: Context) -> MedicationRemindersEntry {
        MedicationRemindersEntry(date: Date(), medications: [], nextDose: nil)
    }
    
    public func getSnapshot(in context: Context, completion: @escaping (MedicationRemindersEntry) -> ()) {
        let medications = [MedicationReminder(name: "Aspirin", dosage: "100mg", time: Date(), taken: false)]
        completion(MedicationRemindersEntry(date: Date(), medications: medications, nextDose: Date()))
    }
    
    public func getTimeline(in context: Context, completion: @escaping (Timeline<MedicationRemindersEntry>) -> ()) {
        let medications = [MedicationReminder(name: "Aspirin", dosage: "100mg", time: Date(), taken: false)]
        let entry = MedicationRemindersEntry(date: Date(), medications: medications, nextDose: Date())
        let timeline = Timeline(entries: [entry], policy: .atEnd)
        completion(timeline)
    }
}

// MARK: - Widget Views

@available(iOS 14.0, *)
public struct DailyHealthSummaryWidgetView: View {
    public let entry: DailyHealthSummaryEntry
    
    public var body: some View {
        VStack {
            Text("Daily Summary")
                .font(.headline)
            Text("\(entry.steps) steps")
                .font(.subheadline)
            Text("\(entry.calories) cal")
                .font(.caption)
        }
        .padding()
    }
}

@available(iOS 14.0, *)
public struct QuickHealthInsightsWidgetView: View {
    public let entry: QuickHealthInsightsEntry
    
    public var body: some View {
        VStack {
            Text("Health Insights")
                .font(.headline)
            if let firstInsight = entry.insights.first {
                Text(firstInsight.title)
                    .font(.subheadline)
            }
        }
        .padding()
    }
}

@available(iOS 14.0, *)
public struct GoalProgressTrackingWidgetView: View {
    public let entry: GoalProgressEntry
    
    public var body: some View {
        VStack {
            Text("Goal Progress")
                .font(.headline)
            Text("\(Int(entry.overallProgress * 100))%")
                .font(.title)
        }
        .padding()
    }
}

@available(iOS 14.0, *)
public struct EmergencyHealthAlertsWidgetView: View {
    public let entry: EmergencyAlertsEntry
    
    public var body: some View {
        VStack {
            Text("Health Alerts")
                .font(.headline)
            Text("\(entry.criticalCount) critical")
                .font(.subheadline)
        }
        .padding()
    }
}

@available(iOS 14.0, *)
public struct MedicationRemindersWidgetView: View {
    public let entry: MedicationRemindersEntry
    
    public var body: some View {
        VStack {
            Text("Medications")
                .font(.headline)
            if let nextDose = entry.nextDose {
                Text("Next: \(nextDose, style: .time)")
                    .font(.subheadline)
            }
        }
        .padding()
    }
} 