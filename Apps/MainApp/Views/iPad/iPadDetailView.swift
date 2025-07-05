import SwiftUI
import Charts
import PencilKit

struct iPadDetailView: View {
    let item: HealthItem?
    @State private var showingAnnotation = false
    @State private var annotationImage: UIImage?
    
    var body: some View {
        Group {
            if let item = item {
                switch item.type {
                case .healthCategory(let category):
                    HealthCategoryDetailView(category: category)
                case .conversation(let conversationId):
                    ConversationDetailView(conversationId: conversationId)
                case .workout(let workoutType):
                    WorkoutDetailView(workoutType: workoutType)
                case .sleepSession(let date):
                    SleepSessionDetailView(date: date)
                case .medication(let medicationName):
                    MedicationDetailView(medicationName: medicationName)
                case .familyMember(let memberName):
                    FamilyMemberDetailView(memberName: memberName)
                }
            } else {
                ContentUnavailableView("Select an Item", systemImage: "sidebar.left")
            }
        }
        .toolbar {
            if item != nil {
                ToolbarItemGroup(placement: .primaryAction) {
                    Button("Annotate") {
                        showingAnnotation = true
                    }
                    .disabled(item?.type != .healthCategory)
                    
                    Button("Share") {
                        // Share functionality
                    }
                    
                    Button("Export") {
                        // Export functionality
                    }
                }
            }
        }
        .sheet(isPresented: $showingAnnotation) {
            AnnotationView(item: item) { image in
                annotationImage = image
                showingAnnotation = false
            }
        }
    }
}

// MARK: - Health Category Detail View

struct HealthCategoryDetailView: View {
    let category: HealthCategory
    @StateObject private var analyticsManager = AnalyticsManager()
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 12) {
                    HStack {
                        Image(systemName: category.icon)
                            .font(.system(size: 40))
                            .foregroundColor(category.color)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(category.rawValue)
                                .font(.largeTitle)
                                .fontWeight(.bold)
                            
                            Text("Detailed analysis and trends")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                    }
                }
                
                // Key Metrics
                KeyMetricsSection(category: category)
                
                // Chart
                ChartSection(category: category, analyticsManager: analyticsManager)
                
                // Insights
                InsightsSection(category: category)
                
                // Recommendations
                RecommendationsSection(category: category)
            }
            .padding(24)
        }
        .navigationTitle(category.rawValue)
        .onAppear {
            analyticsManager.loadData(for: .week)
        }
    }
}

struct KeyMetricsSection: View {
    let category: HealthCategory
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Key Metrics")
                .font(.title2)
                .fontWeight(.bold)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                MetricCard(
                    title: "Current",
                    value: getCurrentValue(),
                    unit: getUnit(),
                    trend: "+2.3%",
                    trendDirection: .up
                )
                
                MetricCard(
                    title: "Average",
                    value: getAverageValue(),
                    unit: getUnit(),
                    trend: "This week",
                    trendDirection: .neutral
                )
                
                MetricCard(
                    title: "Goal",
                    value: getGoalValue(),
                    unit: getUnit(),
                    trend: "85% complete",
                    trendDirection: .up
                )
            }
        }
    }
    
    private func getCurrentValue() -> String {
        switch category {
        case .heartRate: return "72"
        case .steps: return "8,234"
        case .sleep: return "7.5"
        case .calories: return "2,145"
        case .activity: return "45"
        case .weight: return "165"
        case .bloodPressure: return "120/80"
        case .glucose: return "95"
        case .oxygen: return "98"
        case .respiratory: return "16"
        }
    }
    
    private func getAverageValue() -> String {
        switch category {
        case .heartRate: return "74"
        case .steps: return "7,890"
        case .sleep: return "7.2"
        case .calories: return "2,100"
        case .activity: return "42"
        case .weight: return "166"
        case .bloodPressure: return "118/78"
        case .glucose: return "92"
        case .oxygen: return "97"
        case .respiratory: return "15"
        }
    }
    
    private func getGoalValue() -> String {
        switch category {
        case .heartRate: return "<80"
        case .steps: return "10,000"
        case .sleep: return "8.0"
        case .calories: return "2,500"
        case .activity: return "60"
        case .weight: return "160"
        case .bloodPressure: return "<120/80"
        case .glucose: return "<100"
        case .oxygen: return ">95"
        case .respiratory: return "12-20"
        }
    }
    
    private func getUnit() -> String {
        switch category {
        case .heartRate: return "BPM"
        case .steps: return "steps"
        case .sleep: return "hours"
        case .calories: return "kcal"
        case .activity: return "min"
        case .weight: return "lbs"
        case .bloodPressure: return "mmHg"
        case .glucose: return "mg/dL"
        case .oxygen: return "%"
        case .respiratory: return "breaths/min"
        }
    }
}

struct MetricCard: View {
    let title: String
    let value: String
    let unit: String
    let trend: String
    let trendDirection: TrendDirection
    
    enum TrendDirection {
        case up, down, neutral
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            
            HStack(alignment: .bottom, spacing: 4) {
                Text(value)
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text(unit)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            HStack(spacing: 4) {
                Image(systemName: trendDirection == .up ? "arrow.up.right" : 
                              trendDirection == .down ? "arrow.down.right" : "minus")
                    .font(.caption)
                    .foregroundColor(trendDirection == .up ? .green : 
                                   trendDirection == .down ? .red : .secondary)
                
                Text(trend)
                    .font(.caption)
                    .foregroundColor(trendDirection == .up ? .green : 
                                   trendDirection == .down ? .red : .secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
}

struct ChartSection: View {
    let category: HealthCategory
    @ObservedObject var analyticsManager: AnalyticsManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Trends")
                .font(.title2)
                .fontWeight(.bold)
            
            Chart(analyticsManager.heartRateData) { dataPoint in
                LineMark(
                    x: .value("Time", dataPoint.date),
                    y: .value("Value", dataPoint.value)
                )
                .foregroundStyle(category.color)
                .lineStyle(StrokeStyle(lineWidth: 2))
                
                AreaMark(
                    x: .value("Time", dataPoint.date),
                    y: .value("Value", dataPoint.value)
                )
                .foregroundStyle(category.color.opacity(0.1))
            }
            .frame(height: 200)
            .chartYAxis {
                AxisMarks(position: .leading)
            }
            .chartXAxis {
                AxisMarks(values: .stride(by: .day)) { value in
                    AxisGridLine()
                    AxisValueLabel(format: .dateTime.weekday())
                }
            }
        }
    }
}

struct InsightsSection: View {
    let category: HealthCategory
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Insights")
                .font(.title2)
                .fontWeight(.bold)
            
            VStack(spacing: 12) {
                InsightRow(
                    icon: "lightbulb.fill",
                    title: "Positive Trend",
                    description: "Your \(category.rawValue.lowercased()) has improved by 5% this week",
                    color: .green
                )
                
                InsightRow(
                    icon: "clock.fill",
                    title: "Best Time",
                    description: "Your \(category.rawValue.lowercased()) is typically best in the morning",
                    color: .blue
                )
                
                InsightRow(
                    icon: "target",
                    title: "Goal Progress",
                    description: "You're 85% of the way to your \(category.rawValue.lowercased()) goal",
                    color: .orange
                )
            }
        }
    }
}

struct InsightRow: View {
    let icon: String
    let title: String
    let description: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding(12)
        .background(color.opacity(0.1))
        .cornerRadius(8)
    }
}

struct RecommendationsSection: View {
    let category: HealthCategory
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Recommendations")
                .font(.title2)
                .fontWeight(.bold)
            
            VStack(spacing: 12) {
                RecommendationRow(
                    title: "Increase Activity",
                    description: "Try adding 10 more minutes of exercise daily",
                    action: "View Plan"
                )
                
                RecommendationRow(
                    title: "Monitor Trends",
                    description: "Check your \(category.rawValue.lowercased()) at the same time daily",
                    action: "Set Reminder"
                )
            }
        }
    }
}

struct RecommendationRow: View {
    let title: String
    let description: String
    let action: String
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Button(action) {
                // Action
            }
            .font(.caption)
            .foregroundColor(.blue)
        }
        .padding(12)
        .background(Color(.tertiarySystemBackground))
        .cornerRadius(8)
    }
}

// MARK: - Conversation Detail View

struct ConversationDetailView: View {
    let conversationId: String
    @State private var messageText = ""
    
    var body: some View {
        VStack {
            // Chat messages would go here
            ScrollView {
                VStack(spacing: 16) {
                    MessageBubble(
                        text: "Hello! How can I help you with your health today?",
                        isUser: false
                    )
                    
                    MessageBubble(
                        text: "I'd like to know more about my heart rate trends",
                        isUser: true
                    )
                    
                    MessageBubble(
                        text: "I can see your heart rate has been averaging 72 BPM this week, which is excellent! Your resting heart rate has decreased by 3 BPM compared to last month.",
                        isUser: false
                    )
                }
                .padding()
            }
            
            // Message input
            HStack {
                TextField("Type a message...", text: $messageText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                
                Button("Send") {
                    // Send message
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
        }
        .navigationTitle("AI Copilot")
    }
}

struct MessageBubble: View {
    let text: String
    let isUser: Bool
    
    var body: some View {
        HStack {
            if isUser { Spacer() }
            
            Text(text)
                .padding(12)
                .background(isUser ? Color.blue : Color(.secondarySystemBackground))
                .foregroundColor(isUser ? .white : .primary)
                .cornerRadius(16)
                .frame(maxWidth: UIScreen.main.bounds.width * 0.7, alignment: isUser ? .trailing : .leading)
            
            if !isUser { Spacer() }
        }
    }
}

// MARK: - Other Detail Views (Simplified for brevity)

struct WorkoutDetailView: View {
    let workoutType: WorkoutType
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: workoutType.icon)
                .font(.system(size: 60))
                .foregroundColor(.green)
            
            Text(workoutType.rawValue)
                .font(.title)
                .fontWeight(.bold)
            
            Text("Detailed workout analysis and planning for \(workoutType.rawValue.lowercased())")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Spacer()
        }
        .padding()
        .navigationTitle(workoutType.rawValue)
    }
}

struct SleepSessionDetailView: View {
    let date: Date
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "bed.double.fill")
                .font(.system(size: 60))
                .foregroundColor(.blue)
            
            Text("Sleep Analysis")
                .font(.title)
                .fontWeight(.bold)
            
            Text("Detailed sleep analysis for \(date.formatted(date: .abbreviated, time: .omitted))")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Spacer()
        }
        .padding()
        .navigationTitle("Sleep Analysis")
    }
}

struct MedicationDetailView: View {
    let medicationName: String
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "pill.fill")
                .font(.system(size: 60))
                .foregroundColor(.mint)
            
            Text(medicationName)
                .font(.title)
                .fontWeight(.bold)
            
            Text("Medication details and tracking for \(medicationName)")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Spacer()
        }
        .padding()
        .navigationTitle(medicationName)
    }
}

struct FamilyMemberDetailView: View {
    let memberName: String
    
    var body: some View {
        VStack(spacing: 20) {
            Circle()
                .fill(Color.cyan)
                .frame(width: 100, height: 100)
                .overlay(
                    Text(String(memberName.prefix(2)))
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                )
            
            Text(memberName)
                .font(.title)
                .fontWeight(.bold)
            
            Text("Family member health overview and management")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Spacer()
        }
        .padding()
        .navigationTitle(memberName)
    }
}

// MARK: - Annotation View

struct AnnotationView: View {
    let item: HealthItem?
    let onSave: (UIImage) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var canvasView = PKCanvasView()
    
    var body: some View {
        NavigationView {
            VStack {
                // Placeholder for chart/image to annotate
                Rectangle()
                    .fill(Color(.secondarySystemBackground))
                    .overlay(
                        Text("Chart/Image to Annotate")
                            .foregroundColor(.secondary)
                    )
                    .frame(height: 300)
                
                // PencilKit canvas overlay
                PKCanvasRepresentable(canvasView: $canvasView)
                    .frame(height: 300)
                    .border(Color.gray, width: 1)
            }
            .navigationTitle("Annotate")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        // Capture the annotated image
                        let renderer = UIGraphicsImageRenderer(bounds: canvasView.bounds)
                        let image = renderer.image { context in
                            canvasView.layer.render(in: context.cgContext)
                        }
                        onSave(image)
                    }
                }
            }
        }
    }
}

struct PKCanvasRepresentable: UIViewRepresentable {
    @Binding var canvasView: PKCanvasView
    
    func makeUIView(context: Context) -> PKCanvasView {
        canvasView.tool = PKInkingTool(.pen, color: .black, width: 2)
        canvasView.drawingPolicy = .anyInput
        return canvasView
    }
    
    func updateUIView(_ uiView: PKCanvasView, context: Context) {
        // Updates if needed
    }
}

#Preview {
    iPadDetailView(item: HealthItem(
        title: "Heart Rate",
        subtitle: "View detailed data and trends",
        type: .healthCategory(.heartRate),
        icon: "heart.fill",
        color: .red
    ))
} 