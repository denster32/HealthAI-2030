import SwiftUI
import PencilKit

@available(iOS 17.0, *)
public struct IPadOptimizedDashboardView: View {
    @State private var selectedSection: DashboardSection = .overview
    @State private var selectedDetail: DashboardDetail?
    @State private var showingPencilKit = false
    @State private var drawing = PKDrawing()
    
    public var body: some View {
        NavigationSplitView {
            // Sidebar
            IPadSidebarView(selectedSection: $selectedSection)
        } content: {
            // Content List
            IPadContentView(selectedSection: selectedSection, selectedDetail: $selectedDetail)
        } detail: {
            // Detail View
            if let detail = selectedDetail {
                IPadDetailView(detail: detail)
            } else {
                IPadPlaceholderView()
            }
        }
        .navigationSplitViewStyle(.balanced)
        .toolbar {
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                // PencilKit integration
                Button(action: { showingPencilKit = true }) {
                    Image(systemName: "pencil.tip")
                }
                .accessibilityLabel("Open PencilKit")
                
                // Multitasking support
                Button(action: {}) {
                    Image(systemName: "rectangle.split.3x3")
                }
                .accessibilityLabel("Multitasking")
            }
        }
        .sheet(isPresented: $showingPencilKit) {
            IPadPencilKitView(drawing: $drawing)
        }
    }
}

// MARK: - Dashboard Sections
public enum DashboardSection: String, CaseIterable {
    case overview = "Overview"
    case health = "Health"
    case analytics = "Analytics"
    case sleep = "Sleep"
    case activity = "Activity"
    case nutrition = "Nutrition"
    case mentalHealth = "Mental Health"
    case settings = "Settings"
    
    var icon: String {
        switch self {
        case .overview: return "house.fill"
        case .health: return "heart.fill"
        case .analytics: return "chart.bar.fill"
        case .sleep: return "bed.double.fill"
        case .activity: return "figure.run"
        case .nutrition: return "leaf.fill"
        case .mentalHealth: return "brain.head.profile"
        case .settings: return "gear"
        }
    }
    
    var details: [DashboardDetail] {
        switch self {
        case .overview:
            return [
                DashboardDetail(id: "summary", title: "Health Summary", icon: "heart.text.square"),
                DashboardDetail(id: "trends", title: "Trends", icon: "chart.line.uptrend.xyaxis"),
                DashboardDetail(id: "alerts", title: "Alerts", icon: "exclamationmark.triangle")
            ]
        case .health:
            return [
                DashboardDetail(id: "heartRate", title: "Heart Rate", icon: "heart.fill"),
                DashboardDetail(id: "bloodPressure", title: "Blood Pressure", icon: "drop.fill"),
                DashboardDetail(id: "oxygen", title: "Oxygen", icon: "lungs.fill"),
                DashboardDetail(id: "temperature", title: "Temperature", icon: "thermometer")
            ]
        case .analytics:
            return [
                DashboardDetail(id: "predictions", title: "AI Predictions", icon: "brain.head.profile"),
                DashboardDetail(id: "insights", title: "Insights", icon: "lightbulb.fill"),
                DashboardDetail(id: "reports", title: "Reports", icon: "doc.text.fill")
            ]
        case .sleep:
            return [
                DashboardDetail(id: "sleepQuality", title: "Sleep Quality", icon: "bed.double.fill"),
                DashboardDetail(id: "sleepStages", title: "Sleep Stages", icon: "chart.bar.fill"),
                DashboardDetail(id: "sleepTrends", title: "Sleep Trends", icon: "chart.line.uptrend.xyaxis")
            ]
        case .activity:
            return [
                DashboardDetail(id: "steps", title: "Steps", icon: "figure.walk"),
                DashboardDetail(id: "workouts", title: "Workouts", icon: "figure.run"),
                DashboardDetail(id: "calories", title: "Calories", icon: "flame.fill")
            ]
        case .nutrition:
            return [
                DashboardDetail(id: "water", title: "Water Intake", icon: "drop.fill"),
                DashboardDetail(id: "meals", title: "Meals", icon: "fork.knife"),
                DashboardDetail(id: "supplements", title: "Supplements", icon: "pills.fill")
            ]
        case .mentalHealth:
            return [
                DashboardDetail(id: "mood", title: "Mood Tracking", icon: "face.smiling"),
                DashboardDetail(id: "meditation", title: "Meditation", icon: "brain.head.profile"),
                DashboardDetail(id: "stress", title: "Stress Level", icon: "heart.circle")
            ]
        case .settings:
            return [
                DashboardDetail(id: "profile", title: "Profile", icon: "person.fill"),
                DashboardDetail(id: "privacy", title: "Privacy", icon: "lock.fill"),
                DashboardDetail(id: "notifications", title: "Notifications", icon: "bell.fill")
            ]
        }
    }
}

// MARK: - Dashboard Detail
public struct DashboardDetail: Identifiable, Hashable {
    public let id: String
    public let title: String
    public let icon: String
    
    public init(id: String, title: String, icon: String) {
        self.id = id
        self.title = title
        self.icon = icon
    }
}

// MARK: - Sidebar View
struct IPadSidebarView: View {
    @Binding var selectedSection: DashboardSection
    
    var body: some View {
        List(DashboardSection.allCases, id: \.self, selection: $selectedSection) { section in
            NavigationLink(value: section) {
                HStack {
                    Image(systemName: section.icon)
                        .foregroundColor(HealthAIDesignSystem.Colors.primary)
                        .frame(width: 24)
                    
                    Text(section.title)
                        .font(HealthAIDesignSystem.Typography.body)
                }
            }
        }
        .navigationTitle("HealthAI")
        .listStyle(SidebarListStyle())
    }
}

// MARK: - Content View
struct IPadContentView: View {
    let selectedSection: DashboardSection
    @Binding var selectedDetail: DashboardDetail?
    
    var body: some View {
        VStack {
            // Section Header
            HStack {
                Text(selectedSection.title)
                    .font(HealthAIDesignSystem.Typography.largeTitle)
                    .fontWeight(.bold)
                
                Spacer()
                
                // Section Actions
                HStack(spacing: HealthAIDesignSystem.Spacing.md) {
                    Button("Add") {
                        // Add action
                    }
                    .buttonStyle(.borderedProminent)
                    
                    Button("Filter") {
                        // Filter action
                    }
                    .buttonStyle(.bordered)
                }
            }
            .padding()
            
            // Content Grid
            ScrollView {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: HealthAIDesignSystem.Spacing.lg), count: 2), spacing: HealthAIDesignSystem.Spacing.lg) {
                    ForEach(selectedSection.details, id: \.id) { detail in
                        IPadDetailCard(detail: detail)
                            .onTapGesture {
                                selectedDetail = detail
                            }
                    }
                }
                .padding()
            }
        }
    }
}

// MARK: - Detail Card
struct IPadDetailCard: View {
    let detail: DashboardDetail
    @State private var isHovered = false
    
    var body: some View {
        VStack(spacing: HealthAIDesignSystem.Spacing.md) {
            HStack {
                Image(systemName: detail.icon)
                    .foregroundColor(HealthAIDesignSystem.Colors.primary)
                    .font(.title2)
                
                Spacer()
                
                Text("85%")
                    .font(HealthAIDesignSystem.Typography.title2)
                    .fontWeight(.bold)
                    .foregroundColor(HealthAIDesignSystem.Colors.primary)
            }
            
            Text(detail.title)
                .font(HealthAIDesignSystem.Typography.headline)
                .foregroundColor(HealthAIDesignSystem.Colors.textPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            HealthAIProgressView(value: 0.85, color: HealthAIDesignSystem.Colors.primary)
        }
        .padding(HealthAIDesignSystem.Spacing.lg)
        .background(HealthAIDesignSystem.Colors.card)
        .cornerRadius(HealthAIDesignSystem.Layout.cornerRadius)
        .shadow(radius: isHovered ? HealthAIDesignSystem.Layout.shadowRadius : HealthAIDesignSystem.Layout.shadowRadiusSmall)
        .scaleEffect(isHovered ? 1.02 : 1.0)
        .animation(HealthAIDesignSystem.Layout.animationSpring, value: isHovered)
        #if os(macOS)
        .onHover { hovering in
            isHovered = hovering
        }
        #endif
    }
}

// MARK: - Detail View
struct IPadDetailView: View {
    let detail: DashboardDetail
    
    var body: some View {
        VStack {
            Text("Detail View for \(detail.title)")
                .font(HealthAIDesignSystem.Typography.largeTitle)
                .fontWeight(.bold)
            
            Text("This is the detailed view for \(detail.title.lowercased())")
                .font(HealthAIDesignSystem.Typography.body)
                .foregroundColor(HealthAIDesignSystem.Colors.textSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(HealthAIDesignSystem.Colors.background)
    }
}

// MARK: - Placeholder View
struct IPadPlaceholderView: View {
    var body: some View {
        VStack {
            Image(systemName: "square.dashed")
                .font(.system(size: 64, weight: .light))
                .foregroundColor(HealthAIDesignSystem.Colors.textTertiary)
            
            Text("Select an item to view details")
                .font(HealthAIDesignSystem.Typography.title2)
                .foregroundColor(HealthAIDesignSystem.Colors.textSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(HealthAIDesignSystem.Colors.background)
    }
}

// MARK: - PencilKit Integration
struct IPadPencilKitView: View {
    @Binding var drawing: PKDrawing
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            VStack {
                Text("Health Journal")
                    .font(HealthAIDesignSystem.Typography.title1)
                    .fontWeight(.bold)
                    .padding()
                
                PencilKitView(drawing: $drawing)
                    .frame(maxHeight: .infinity)
            }
            .navigationTitle("Health Journal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        // Save drawing
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - PencilKit SwiftUI Wrapper
struct PencilKitView: UIViewRepresentable {
    @Binding var drawing: PKDrawing
    
    func makeUIView(context: Context) -> PKCanvasView {
        let canvas = PKCanvasView()
        canvas.drawing = drawing
        canvas.tool = PKInkingTool(.pen, color: .systemBlue, width: 1)
        return canvas
    }
    
    func updateUIView(_ uiView: PKCanvasView, context: Context) {
        uiView.drawing = drawing
    }
} 