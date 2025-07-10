import SwiftUI
import Charts

// MARK: - Health Timeline Visualizations
/// Comprehensive timeline visualization components for health data and medical events
/// Provides interactive timeline views for tracking health progress and medical history
public struct HealthTimelineVisualizations {
    
    // MARK: - Health Data Timeline
    
    /// Interactive timeline for health data visualization
    public struct HealthDataTimeline: View {
        let healthEvents: [HealthEvent]
        let selectedDate: Date?
        let onDateSelected: (Date) -> Void
        @State private var selectedTimeRange: TimeRange = .month
        @State private var isExpanded: Bool = false
        
        public init(
            healthEvents: [HealthEvent],
            selectedDate: Date? = nil,
            onDateSelected: @escaping (Date) -> Void
        ) {
            self.healthEvents = healthEvents
            self.selectedDate = selectedDate
            self.onDateSelected = onDateSelected
        }
        
        public var body: some View {
            VStack(spacing: 20) {
                // Timeline Header
                HStack {
                    Text("Health Timeline")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Spacer()
                    
                    // Time Range Selector
                    Picker("Time Range", selection: $selectedTimeRange) {
                        ForEach(TimeRange.allCases, id: \.self) { range in
                            Text(range.displayName).tag(range)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .frame(width: 200)
                }
                .padding(.horizontal)
                
                // Interactive Timeline
                ScrollView {
                    LazyVStack(spacing: 16) {
                        ForEach(groupedEvents, id: \.date) { group in
                            TimelineGroupView(
                                date: group.date,
                                events: group.events,
                                isSelected: selectedDate?.isSameDay(as: group.date) ?? false,
                                onEventTap: { event in
                                    onDateSelected(event.date)
                                }
                            )
                        }
                    }
                    .padding(.horizontal)
                }
                
                // Timeline Statistics
                if !healthEvents.isEmpty {
                    TimelineStatisticsView(events: healthEvents)
                        .padding(.horizontal)
                }
            }
            .background(Color(.systemBackground))
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
        }
        
        private var groupedEvents: [TimelineGroup] {
            let filteredEvents = healthEvents.filter { event in
                selectedTimeRange.contains(event.date)
            }
            
            let grouped = Dictionary(grouping: filteredEvents) { event in
                Calendar.current.startOfDay(for: event.date)
            }
            
            return grouped.map { TimelineGroup(date: $0.key, events: $0.value) }
                .sorted { $0.date > $1.date }
        }
    }
    
    // MARK: - Medical History Timeline
    
    /// Timeline for medical history and treatment progress
    public struct MedicalHistoryTimeline: View {
        let medicalEvents: [MedicalEvent]
        let treatmentProgress: [TreatmentProgress]
        @State private var selectedCategory: MedicalEventCategory = .all
        @State private var showingDetails: Bool = false
        
        public init(
            medicalEvents: [MedicalEvent],
            treatmentProgress: [TreatmentProgress] = []
        ) {
            self.medicalEvents = medicalEvents
            self.treatmentProgress = treatmentProgress
        }
        
        public var body: some View {
            VStack(spacing: 20) {
                // Category Filter
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(MedicalEventCategory.allCases, id: \.self) { category in
                            CategoryFilterButton(
                                category: category,
                                isSelected: selectedCategory == category,
                                action: { selectedCategory = category }
                            )
                        }
                    }
                    .padding(.horizontal)
                }
                
                // Timeline Chart
                Chart {
                    ForEach(filteredMedicalEvents, id: \.id) { event in
                        PointMark(
                            x: .value("Date", event.date),
                            y: .value("Severity", event.severity)
                        )
                        .foregroundStyle(event.category.color)
                        .symbolSize(100)
                    }
                    
                    if !treatmentProgress.isEmpty {
                        ForEach(treatmentProgress, id: \.id) { progress in
                            LineMark(
                                x: .value("Date", progress.date),
                                y: .value("Progress", progress.progressPercentage)
                            )
                            .foregroundStyle(.blue)
                            .lineStyle(StrokeStyle(lineWidth: 3))
                        }
                    }
                }
                .frame(height: 200)
                .padding(.horizontal)
                
                // Event List
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(filteredMedicalEvents, id: \.id) { event in
                            MedicalEventCard(event: event)
                        }
                    }
                    .padding(.horizontal)
                }
            }
            .background(Color(.systemBackground))
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
        }
        
        private var filteredMedicalEvents: [MedicalEvent] {
            if selectedCategory == .all {
                return medicalEvents
            }
            return medicalEvents.filter { $0.category == selectedCategory }
        }
    }
    
    // MARK: - Treatment Progress Timeline
    
    /// Timeline for tracking treatment progress and milestones
    public struct TreatmentProgressTimeline: View {
        let treatmentPlan: TreatmentPlan
        let progressData: [TreatmentMilestone]
        @State private var selectedPhase: TreatmentPhase?
        @State private var showingMilestoneDetails: Bool = false
        
        public init(
            treatmentPlan: TreatmentPlan,
            progressData: [TreatmentMilestone] = []
        ) {
            self.treatmentPlan = treatmentPlan
            self.progressData = progressData
        }
        
        public var body: some View {
            VStack(spacing: 20) {
                // Treatment Overview
                TreatmentOverviewCard(treatmentPlan: treatmentPlan)
                    .padding(.horizontal)
                
                // Progress Timeline
                VStack(spacing: 16) {
                    ForEach(treatmentPlan.phases, id: \.id) { phase in
                        TreatmentPhaseView(
                            phase: phase,
                            milestones: milestonesForPhase(phase),
                            isSelected: selectedPhase?.id == phase.id,
                            onPhaseTap: { selectedPhase = phase }
                        )
                    }
                }
                .padding(.horizontal)
                
                // Progress Chart
                if !progressData.isEmpty {
                    TreatmentProgressChart(
                        progressData: progressData,
                        treatmentPlan: treatmentPlan
                    )
                    .frame(height: 150)
                    .padding(.horizontal)
                }
            }
            .background(Color(.systemBackground))
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
        }
        
        private func milestonesForPhase(_ phase: TreatmentPhase) -> [TreatmentMilestone] {
            return progressData.filter { milestone in
                milestone.phaseId == phase.id
            }
        }
    }
    
    // MARK: - Medication Timeline
    
    /// Timeline for medication tracking and adherence
    public struct MedicationTimeline: View {
        let medications: [MedicationSchedule]
        let adherenceData: [MedicationAdherence]
        @State private var selectedMedication: MedicationSchedule?
        @State private var showingAdherenceDetails: Bool = false
        
        public init(
            medications: [MedicationSchedule],
            adherenceData: [MedicationAdherence] = []
        ) {
            self.medications = medications
            self.adherenceData = adherenceData
        }
        
        public var body: some View {
            VStack(spacing: 20) {
                // Medication List
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(medications, id: \.id) { medication in
                            MedicationCard(
                                medication: medication,
                                isSelected: selectedMedication?.id == medication.id,
                                onTap: { selectedMedication = medication }
                            )
                        }
                    }
                    .padding(.horizontal)
                }
                
                // Adherence Timeline
                if let selectedMed = selectedMedication {
                    MedicationAdherenceTimeline(
                        medication: selectedMed,
                        adherenceData: adherenceDataForMedication(selectedMed)
                    )
                    .padding(.horizontal)
                }
                
                // Overall Adherence Chart
                if !adherenceData.isEmpty {
                    OverallAdherenceChart(adherenceData: adherenceData)
                        .frame(height: 120)
                        .padding(.horizontal)
                }
            }
            .background(Color(.systemBackground))
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
        }
        
        private func adherenceDataForMedication(_ medication: MedicationSchedule) -> [MedicationAdherence] {
            return adherenceData.filter { $0.medicationId == medication.id }
        }
    }
}

// MARK: - Supporting Views

struct TimelineGroupView: View {
    let date: Date
    let events: [HealthEvent]
    let isSelected: Bool
    let onEventTap: (HealthEvent) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Date Header
            HStack {
                Text(date.formatted(date: .abbreviated, time: .omitted))
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Text("\(events.count) events")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            // Events
            ForEach(events, id: \.id) { event in
                HealthEventRow(event: event, onTap: onEventTap)
            }
        }
        .padding()
        .background(isSelected ? Color.blue.opacity(0.1) : Color(.systemGray6))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
        )
    }
}

struct HealthEventRow: View {
    let event: HealthEvent
    let onTap: (HealthEvent) -> Void
    
    var body: some View {
        Button(action: { onTap(event) }) {
            HStack(spacing: 12) {
                // Event Icon
                Image(systemName: event.type.iconName)
                    .foregroundColor(event.type.color)
                    .frame(width: 24, height: 24)
                
                // Event Details
                VStack(alignment: .leading, spacing: 4) {
                    Text(event.title)
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Text(event.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
                
                Spacer()
                
                // Time
                Text(event.date.formatted(date: .omitted, time: .shortened))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.vertical, 8)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct TimelineStatisticsView: View {
    let events: [HealthEvent]
    
    var body: some View {
        VStack(spacing: 12) {
            Text("Timeline Statistics")
                .font(.headline)
                .fontWeight(.semibold)
            
            HStack(spacing: 20) {
                StatCard(
                    title: "Total Events",
                    value: "\(events.count)",
                    icon: "calendar"
                )
                
                StatCard(
                    title: "This Month",
                    value: "\(eventsThisMonth)",
                    icon: "calendar.badge.clock"
                )
                
                StatCard(
                    title: "Categories",
                    value: "\(uniqueCategories)",
                    icon: "tag"
                )
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private var eventsThisMonth: Int {
        let calendar = Calendar.current
        let now = Date()
        return events.filter { event in
            calendar.isDate(event.date, equalTo: now, toGranularity: .month)
        }.count
    }
    
    private var uniqueCategories: Int {
        Set(events.map { $0.type }).count
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.blue)
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(8)
    }
}

// MARK: - Data Models

struct HealthEvent: Identifiable {
    let id = UUID()
    let title: String
    let description: String
    let date: Date
    let type: HealthEventType
    let severity: Double?
    let metadata: [String: Any]?
}

enum HealthEventType: CaseIterable {
    case appointment
    case medication
    case exercise
    case nutrition
    case sleep
    case vitalSigns
    case symptom
    case treatment
    
    var iconName: String {
        switch self {
        case .appointment: return "calendar"
        case .medication: return "pills"
        case .exercise: return "figure.walk"
        case .nutrition: return "leaf"
        case .sleep: return "bed.double"
        case .vitalSigns: return "heart"
        case .symptom: return "exclamationmark.triangle"
        case .treatment: return "cross"
        }
    }
    
    var color: Color {
        switch self {
        case .appointment: return .blue
        case .medication: return .purple
        case .exercise: return .green
        case .nutrition: return .orange
        case .sleep: return .indigo
        case .vitalSigns: return .red
        case .symptom: return .yellow
        case .treatment: return .teal
        }
    }
}

enum TimeRange: CaseIterable {
    case week
    case month
    case quarter
    case year
    
    var displayName: String {
        switch self {
        case .week: return "Week"
        case .month: return "Month"
        case .quarter: return "Quarter"
        case .year: return "Year"
        }
    }
    
    func contains(_ date: Date) -> Bool {
        let calendar = Calendar.current
        let now = Date()
        
        switch self {
        case .week:
            return calendar.isDate(date, equalTo: now, toGranularity: .weekOfYear)
        case .month:
            return calendar.isDate(date, equalTo: now, toGranularity: .month)
        case .quarter:
            let quarter = (calendar.component(.month, from: now) - 1) / 3
            let eventQuarter = (calendar.component(.month, from: date) - 1) / 3
            return quarter == eventQuarter && calendar.isDate(date, equalTo: now, toGranularity: .year)
        case .year:
            return calendar.isDate(date, equalTo: now, toGranularity: .year)
        }
    }
}

struct TimelineGroup {
    let date: Date
    let events: [HealthEvent]
}

struct MedicalEvent: Identifiable {
    let id = UUID()
    let title: String
    let description: String
    let date: Date
    let category: MedicalEventCategory
    let severity: Double
    let doctor: String?
    let location: String?
}

enum MedicalEventCategory: CaseIterable {
    case all
    case appointment
    case diagnosis
    case treatment
    case surgery
    case medication
    case test
    case followUp
    
    var color: Color {
        switch self {
        case .all: return .gray
        case .appointment: return .blue
        case .diagnosis: return .orange
        case .treatment: return .green
        case .surgery: return .red
        case .medication: return .purple
        case .test: return .yellow
        case .followUp: return .teal
        }
    }
}

struct TreatmentProgress: Identifiable {
    let id = UUID()
    let date: Date
    let progressPercentage: Double
    let notes: String?
}

struct TreatmentPlan {
    let id = UUID()
    let title: String
    let description: String
    let phases: [TreatmentPhase]
    let startDate: Date
    let endDate: Date?
}

struct TreatmentPhase: Identifiable {
    let id = UUID()
    let name: String
    let description: String
    let startDate: Date
    let endDate: Date
    let milestones: [String]
}

struct TreatmentMilestone: Identifiable {
    let id = UUID()
    let phaseId: UUID
    let title: String
    let description: String
    let date: Date
    let isCompleted: Bool
}

struct MedicationSchedule: Identifiable {
    let id = UUID()
    let name: String
    let dosage: String
    let frequency: String
    let startDate: Date
    let endDate: Date?
    let instructions: String?
}

struct MedicationAdherence: Identifiable {
    let id = UUID()
    let medicationId: UUID
    let date: Date
    let taken: Bool
    let timeTaken: Date?
    let notes: String?
}

// MARK: - Supporting Views for Medical Timeline

struct CategoryFilterButton: View {
    let category: MedicalEventCategory
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(category.displayName)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(isSelected ? .white : .primary)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isSelected ? category.color : Color(.systemGray5))
                .cornerRadius(16)
        }
    }
}

extension MedicalEventCategory {
    var displayName: String {
        switch self {
        case .all: return "All"
        case .appointment: return "Appointments"
        case .diagnosis: return "Diagnoses"
        case .treatment: return "Treatments"
        case .surgery: return "Surgeries"
        case .medication: return "Medications"
        case .test: return "Tests"
        case .followUp: return "Follow-ups"
        }
    }
}

struct MedicalEventCard: View {
    let event: MedicalEvent
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(event.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Spacer()
                
                Text(event.date.formatted(date: .abbreviated, time: .omitted))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Text(event.description)
                .font(.caption)
                .foregroundColor(.secondary)
                .lineLimit(2)
            
            HStack {
                Text(event.category.displayName)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(event.category.color.opacity(0.2))
                    .foregroundColor(event.category.color)
                    .cornerRadius(8)
                
                if let doctor = event.doctor {
                    Text("Dr. \(doctor)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

// MARK: - Supporting Views for Treatment Timeline

struct TreatmentOverviewCard: View {
    let treatmentPlan: TreatmentPlan
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(treatmentPlan.title)
                .font(.headline)
                .fontWeight(.semibold)
            
            Text(treatmentPlan.description)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            HStack {
                VStack(alignment: .leading) {
                    Text("Start Date")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(treatmentPlan.startDate.formatted(date: .abbreviated, time: .omitted))
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
                
                Spacer()
                
                if let endDate = treatmentPlan.endDate {
                    VStack(alignment: .trailing) {
                        Text("End Date")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(endDate.formatted(date: .abbreviated, time: .omitted))
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct TreatmentPhaseView: View {
    let phase: TreatmentPhase
    let milestones: [TreatmentMilestone]
    let isSelected: Bool
    let onPhaseTap: () -> Void
    
    var body: some View {
        Button(action: onPhaseTap) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(phase.name)
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Spacer()
                    
                    Text("\(milestones.filter { $0.isCompleted }.count)/\(milestones.count)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Text(phase.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                
                if isSelected && !milestones.isEmpty {
                    VStack(spacing: 4) {
                        ForEach(milestones) { milestone in
                            HStack {
                                Image(systemName: milestone.isCompleted ? "checkmark.circle.fill" : "circle")
                                    .foregroundColor(milestone.isCompleted ? .green : .gray)
                                    .font(.caption)
                                
                                Text(milestone.title)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                
                                Spacer()
                            }
                        }
                    }
                    .padding(.top, 8)
                }
            }
            .padding()
            .background(isSelected ? Color.blue.opacity(0.1) : Color(.systemGray6))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct TreatmentProgressChart: View {
    let progressData: [TreatmentMilestone]
    let treatmentPlan: TreatmentPlan
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Overall Progress")
                .font(.subheadline)
                .fontWeight(.medium)
            
            ProgressView(value: progressPercentage)
                .progressViewStyle(LinearProgressViewStyle(tint: .blue))
            
            HStack {
                Text("\(Int(progressPercentage * 100))% Complete")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text("\(completedMilestones)/\(totalMilestones) Milestones")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private var completedMilestones: Int {
        progressData.filter { $0.isCompleted }.count
    }
    
    private var totalMilestones: Int {
        progressData.count
    }
    
    private var progressPercentage: Double {
        guard totalMilestones > 0 else { return 0 }
        return Double(completedMilestones) / Double(totalMilestones)
    }
}

// MARK: - Supporting Views for Medication Timeline

struct MedicationCard: View {
    let medication: MedicationSchedule
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 8) {
                Text(medication.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .lineLimit(1)
                
                Text(medication.dosage)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text(medication.frequency)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .frame(width: 120)
            .padding()
            .background(isSelected ? Color.blue.opacity(0.1) : Color(.systemGray6))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct MedicationAdherenceTimeline: View {
    let medication: MedicationSchedule
    let adherenceData: [MedicationAdherence]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Adherence for \(medication.name)")
                .font(.subheadline)
                .fontWeight(.medium)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 8) {
                ForEach(last7Days, id: \.self) { date in
                    let adherence = adherenceData.first { Calendar.current.isDate($0.date, inSameDayAs: date) }
                    
                    VStack {
                        Text(date.formatted(.dateTime.weekday(.abbreviated)))
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        
                        Circle()
                            .fill(adherence?.taken == true ? Color.green : Color.red)
                            .frame(width: 20, height: 20)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private var last7Days: [Date] {
        let calendar = Calendar.current
        let today = Date()
        return (0..<7).map { dayOffset in
            calendar.date(byAdding: .day, value: -dayOffset, to: today) ?? today
        }.reversed()
    }
}

struct OverallAdherenceChart: View {
    let adherenceData: [MedicationAdherence]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Overall Adherence")
                .font(.subheadline)
                .fontWeight(.medium)
            
            HStack {
                VStack(alignment: .leading) {
                    Text("\(Int(overallAdherencePercentage * 100))%")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.green)
                    
                    Text("Adherence Rate")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    Text("\(takenCount)/\(totalCount)")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Text("Doses Taken")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private var takenCount: Int {
        adherenceData.filter { $0.taken }.count
    }
    
    private var totalCount: Int {
        adherenceData.count
    }
    
    private var overallAdherencePercentage: Double {
        guard totalCount > 0 else { return 0 }
        return Double(takenCount) / Double(totalCount)
    }
}

// MARK: - Extensions

extension Date {
    func isSameDay(as date: Date) -> Bool {
        Calendar.current.isDate(self, inSameDayAs: date)
    }
} 