import SwiftUI
import TVUIKit

@available(tvOS 17.0, *)
public struct TVOptimizedDashboardView: View {
    @StateObject private var healthManager = TVHealthManager.shared
    @State private var selectedSection: TVDashboardSection = .overview
    @State private var focusedItem: String?
    
    public var body: some View {
        NavigationStack {
            HStack(spacing: HealthAIDesignSystem.Spacing.xl) {
                // Sidebar
                TVSidebarView(selectedSection: $selectedSection, focusedItem: $focusedItem)
                    .frame(width: 300)
                
                // Main Content
                TVMainContentView(selectedSection: selectedSection, focusedItem: $focusedItem)
            }
            .background(HealthAIDesignSystem.Colors.background)
            .navigationTitle("HealthAI")
            .navigationBarTitleDisplayMode(.large)
        }
        .onAppear {
            healthManager.startMonitoring()
        }
        .onDisappear {
            healthManager.stopMonitoring()
        }
    }
}

// MARK: - TV Dashboard Sections
public enum TVDashboardSection: String, CaseIterable {
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
    
    var items: [TVDashboardItem] {
        switch self {
        case .overview:
            return [
                TVDashboardItem(id: "summary", title: "Health Summary", subtitle: "Daily overview", icon: "heart.text.square"),
                TVDashboardItem(id: "trends", title: "Trends", subtitle: "Weekly patterns", icon: "chart.line.uptrend.xyaxis"),
                TVDashboardItem(id: "alerts", title: "Alerts", subtitle: "Important notifications", icon: "exclamationmark.triangle")
            ]
        case .health:
            return [
                TVDashboardItem(id: "heartRate", title: "Heart Rate", subtitle: "Current: 72 BPM", icon: "heart.fill"),
                TVDashboardItem(id: "bloodPressure", title: "Blood Pressure", subtitle: "120/80 mmHg", icon: "drop.fill"),
                TVDashboardItem(id: "oxygen", title: "Oxygen", subtitle: "98% SpO2", icon: "lungs.fill"),
                TVDashboardItem(id: "temperature", title: "Temperature", subtitle: "98.6°F", icon: "thermometer")
            ]
        case .analytics:
            return [
                TVDashboardItem(id: "predictions", title: "AI Predictions", subtitle: "Health insights", icon: "brain.head.profile"),
                TVDashboardItem(id: "insights", title: "Insights", subtitle: "Personalized recommendations", icon: "lightbulb.fill"),
                TVDashboardItem(id: "reports", title: "Reports", subtitle: "Detailed analysis", icon: "doc.text.fill")
            ]
        case .sleep:
            return [
                TVDashboardItem(id: "sleepQuality", title: "Sleep Quality", subtitle: "85% last night", icon: "bed.double.fill"),
                TVDashboardItem(id: "sleepStages", title: "Sleep Stages", subtitle: "Deep, REM, Light", icon: "chart.bar.fill"),
                TVDashboardItem(id: "sleepTrends", title: "Sleep Trends", subtitle: "Weekly patterns", icon: "chart.line.uptrend.xyaxis")
            ]
        case .activity:
            return [
                TVDashboardItem(id: "steps", title: "Steps", subtitle: "8,432 today", icon: "figure.walk"),
                TVDashboardItem(id: "workouts", title: "Workouts", subtitle: "3 this week", icon: "figure.run"),
                TVDashboardItem(id: "calories", title: "Calories", subtitle: "2,145 burned", icon: "flame.fill")
            ]
        case .nutrition:
            return [
                TVDashboardItem(id: "water", title: "Water Intake", subtitle: "6/8 glasses", icon: "drop.fill"),
                TVDashboardItem(id: "meals", title: "Meals", subtitle: "3 logged today", icon: "fork.knife"),
                TVDashboardItem(id: "supplements", title: "Supplements", subtitle: "2 taken", icon: "pills.fill")
            ]
        case .mentalHealth:
            return [
                TVDashboardItem(id: "mood", title: "Mood Tracking", subtitle: "Feeling good", icon: "face.smiling"),
                TVDashboardItem(id: "meditation", title: "Meditation", subtitle: "15 min today", icon: "brain.head.profile"),
                TVDashboardItem(id: "stress", title: "Stress Level", subtitle: "Low stress", icon: "heart.circle")
            ]
        case .settings:
            return [
                TVDashboardItem(id: "profile", title: "Profile", subtitle: "Personal information", icon: "person.fill"),
                TVDashboardItem(id: "privacy", title: "Privacy", subtitle: "Data settings", icon: "lock.fill"),
                TVDashboardItem(id: "notifications", title: "Notifications", subtitle: "Alert preferences", icon: "bell.fill")
            ]
        }
    }
}

// MARK: - TV Dashboard Item
public struct TVDashboardItem: Identifiable, Hashable {
    public let id: String
    public let title: String
    public let subtitle: String
    public let icon: String
    
    public init(id: String, title: String, subtitle: String, icon: String) {
        self.id = id
        self.title = title
        self.subtitle = subtitle
        self.icon = icon
    }
}

// MARK: - TV Sidebar View
struct TVSidebarView: View {
    @Binding var selectedSection: TVDashboardSection
    @Binding var focusedItem: String?
    
    var body: some View {
        VStack(spacing: HealthAIDesignSystem.Spacing.lg) {
            Text("Navigation")
                .font(HealthAIDesignSystem.Typography.title2)
                .fontWeight(.bold)
                .foregroundColor(HealthAIDesignSystem.Colors.textPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            LazyVStack(spacing: HealthAIDesignSystem.Spacing.md) {
                ForEach(TVDashboardSection.allCases, id: \.self) { section in
                    TVSidebarButton(
                        section: section,
                        isSelected: selectedSection == section,
                        focusedItem: $focusedItem
                    ) {
                        selectedSection = section
                        focusedItem = section.items.first?.id
                    }
                }
            }
            
            Spacer()
        }
        .padding(HealthAIDesignSystem.Spacing.lg)
        .background(HealthAIDesignSystem.Colors.surface)
        .cornerRadius(HealthAIDesignSystem.Layout.cornerRadius)
    }
}

// MARK: - TV Sidebar Button
struct TVSidebarButton: View {
    let section: TVDashboardSection
    let isSelected: Bool
    @Binding var focusedItem: String?
    let action: () -> Void
    @State private var isFocused = false
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: HealthAIDesignSystem.Spacing.md) {
                Image(systemName: section.icon)
                    .font(.system(size: 24, weight: .medium))
                    .foregroundColor(buttonColor)
                    .frame(width: 32)
                
                VStack(alignment: .leading, spacing: HealthAIDesignSystem.Spacing.xs) {
                    Text(section.title)
                        .font(HealthAIDesignSystem.Typography.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(buttonColor)
                    
                    Text("\(section.items.count) items")
                        .font(HealthAIDesignSystem.Typography.caption1)
                        .foregroundColor(HealthAIDesignSystem.Colors.textSecondary)
                }
                
                Spacer()
            }
            .padding(HealthAIDesignSystem.Spacing.md)
            .background(buttonBackground)
            .cornerRadius(HealthAIDesignSystem.Layout.cornerRadius)
            .scaleEffect(isFocused ? 1.05 : 1.0)
            .animation(HealthAIDesignSystem.Layout.animationSpring, value: isFocused)
        }
        .buttonStyle(PlainButtonStyle())
        .focused($isFocused)
        .onChange(of: isFocused) { focused in
            if focused {
                focusedItem = section.rawValue
            }
        }
    }
    
    private var buttonColor: Color {
        if isSelected {
            return HealthAIDesignSystem.Colors.primary
        } else if isFocused {
            return HealthAIDesignSystem.Colors.textPrimary
        } else {
            return HealthAIDesignSystem.Colors.textSecondary
        }
    }
    
    private var buttonBackground: some View {
        if isSelected {
            return RoundedRectangle(cornerRadius: HealthAIDesignSystem.Layout.cornerRadius)
                .fill(HealthAIDesignSystem.Colors.primary.opacity(0.2))
        } else if isFocused {
            return RoundedRectangle(cornerRadius: HealthAIDesignSystem.Layout.cornerRadius)
                .fill(HealthAIDesignSystem.Colors.surface)
                .overlay(
                    RoundedRectangle(cornerRadius: HealthAIDesignSystem.Layout.cornerRadius)
                        .stroke(HealthAIDesignSystem.Colors.primary, lineWidth: 2)
                )
        } else {
            return Color.clear
        }
    }
}

// MARK: - TV Main Content View
struct TVMainContentView: View {
    let selectedSection: TVDashboardSection
    @Binding var focusedItem: String?
    
    var body: some View {
        VStack(spacing: HealthAIDesignSystem.Spacing.xl) {
            // Section Header
            HStack {
                Text(selectedSection.title)
                    .font(HealthAIDesignSystem.Typography.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(HealthAIDesignSystem.Colors.textPrimary)
                
                Spacer()
                
                // Section Actions
                HStack(spacing: HealthAIDesignSystem.Spacing.lg) {
                    TVActionButton(title: "Add", icon: "plus", action: {})
                    TVActionButton(title: "Filter", icon: "line.3.horizontal.decrease", action: {})
                    TVActionButton(title: "Export", icon: "square.and.arrow.up", action: {})
                }
            }
            
            // Content Grid
            ScrollView {
                LazyVGrid(
                    columns: Array(repeating: GridItem(.flexible(), spacing: HealthAIDesignSystem.Spacing.lg), count: 3),
                    spacing: HealthAIDesignSystem.Spacing.lg
                ) {
                    ForEach(selectedSection.items, id: \.id) { item in
                        TVDashboardCard(item: item, focusedItem: $focusedItem)
                    }
                }
                .padding()
            }
        }
        .padding(HealthAIDesignSystem.Spacing.xl)
    }
}

// MARK: - TV Dashboard Card
struct TVDashboardCard: View {
    let item: TVDashboardItem
    @Binding var focusedItem: String?
    @State private var isFocused = false
    
    var body: some View {
        VStack(spacing: HealthAIDesignSystem.Spacing.lg) {
            // Icon
            Image(systemName: item.icon)
                .font(.system(size: 48, weight: .medium))
                .foregroundColor(HealthAIDesignSystem.Colors.primary)
            
            // Content
            VStack(spacing: HealthAIDesignSystem.Spacing.sm) {
                Text(item.title)
                    .font(HealthAIDesignSystem.Typography.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(HealthAIDesignSystem.Colors.textPrimary)
                    .multilineTextAlignment(.center)
                
                Text(item.subtitle)
                    .font(HealthAIDesignSystem.Typography.body)
                    .foregroundColor(HealthAIDesignSystem.Colors.textSecondary)
                    .multilineTextAlignment(.center)
            }
            
            // Action Button
            TVCardActionButton(title: "View Details", action: {
                // Navigate to detail view
            })
        }
        .padding(HealthAIDesignSystem.Spacing.xl)
        .background(cardBackground)
        .cornerRadius(HealthAIDesignSystem.Layout.cornerRadius)
        .scaleEffect(isFocused ? 1.05 : 1.0)
        .animation(HealthAIDesignSystem.Layout.animationSpring, value: isFocused)
        .focused($isFocused)
        .onChange(of: isFocused) { focused in
            if focused {
                focusedItem = item.id
            }
        }
    }
    
    private var cardBackground: some View {
        if isFocused {
            return RoundedRectangle(cornerRadius: HealthAIDesignSystem.Layout.cornerRadius)
                .fill(HealthAIDesignSystem.Colors.card)
                .overlay(
                    RoundedRectangle(cornerRadius: HealthAIDesignSystem.Layout.cornerRadius)
                        .stroke(HealthAIDesignSystem.Colors.primary, lineWidth: 3)
                )
                .shadow(radius: HealthAIDesignSystem.Layout.shadowRadius)
        } else {
            return RoundedRectangle(cornerRadius: HealthAIDesignSystem.Layout.cornerRadius)
                .fill(HealthAIDesignSystem.Colors.card)
                .shadow(radius: HealthAIDesignSystem.Layout.shadowRadiusSmall)
        }
    }
}

// MARK: - TV Action Button
struct TVActionButton: View {
    let title: String
    let icon: String
    let action: () -> Void
    @State private var isFocused = false
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: HealthAIDesignSystem.Spacing.sm) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .medium))
                
                Text(title)
                    .font(HealthAIDesignSystem.Typography.body)
                    .fontWeight(.medium)
            }
            .padding(.horizontal, HealthAIDesignSystem.Spacing.lg)
            .padding(.vertical, HealthAIDesignSystem.Spacing.md)
            .background(buttonBackground)
            .foregroundColor(buttonColor)
            .cornerRadius(HealthAIDesignSystem.Layout.cornerRadius)
            .scaleEffect(isFocused ? 1.05 : 1.0)
            .animation(HealthAIDesignSystem.Layout.animationSpring, value: isFocused)
        }
        .buttonStyle(PlainButtonStyle())
        .focused($isFocused)
    }
    
    private var buttonColor: Color {
        isFocused ? HealthAIDesignSystem.Colors.primary : HealthAIDesignSystem.Colors.textPrimary
    }
    
    private var buttonBackground: some View {
        if isFocused {
            return RoundedRectangle(cornerRadius: HealthAIDesignSystem.Layout.cornerRadius)
                .fill(HealthAIDesignSystem.Colors.primary.opacity(0.2))
                .overlay(
                    RoundedRectangle(cornerRadius: HealthAIDesignSystem.Layout.cornerRadius)
                        .stroke(HealthAIDesignSystem.Colors.primary, lineWidth: 2)
                )
        } else {
            return RoundedRectangle(cornerRadius: HealthAIDesignSystem.Layout.cornerRadius)
                .fill(HealthAIDesignSystem.Colors.surface)
        }
    }
}

// MARK: - TV Card Action Button
struct TVCardActionButton: View {
    let title: String
    let action: () -> Void
    @State private var isFocused = false
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(HealthAIDesignSystem.Typography.body)
                .fontWeight(.medium)
                .foregroundColor(buttonColor)
                .padding(.horizontal, HealthAIDesignSystem.Spacing.lg)
                .padding(.vertical, HealthAIDesignSystem.Spacing.md)
                .background(buttonBackground)
                .cornerRadius(HealthAIDesignSystem.Layout.cornerRadius)
                .scaleEffect(isFocused ? 1.05 : 1.0)
                .animation(HealthAIDesignSystem.Layout.animationSpring, value: isFocused)
        }
        .buttonStyle(PlainButtonStyle())
        .focused($isFocused)
    }
    
    private var buttonColor: Color {
        isFocused ? HealthAIDesignSystem.Colors.primary : HealthAIDesignSystem.Colors.textPrimary
    }
    
    private var buttonBackground: some View {
        if isFocused {
            return RoundedRectangle(cornerRadius: HealthAIDesignSystem.Layout.cornerRadius)
                .fill(HealthAIDesignSystem.Colors.primary.opacity(0.2))
                .overlay(
                    RoundedRectangle(cornerRadius: HealthAIDesignSystem.Layout.cornerRadius)
                        .stroke(HealthAIDesignSystem.Colors.primary, lineWidth: 2)
                )
        } else {
            return RoundedRectangle(cornerRadius: HealthAIDesignSystem.Layout.cornerRadius)
                .fill(HealthAIDesignSystem.Colors.surface)
        }
    }
}

// MARK: - TV Health Manager
class TVHealthManager: ObservableObject {
    static let shared = TVHealthManager()
    
    @Published var currentHeartRate: Double = 72.0
    @Published var bloodPressure: (systolic: Int, diastolic: Int) = (120, 80)
    @Published var oxygenLevel: Double = 98.0
    @Published var temperature: Double = 98.6
    @Published var sleepQuality: Double = 0.85
    @Published var activityLevel: Double = 0.75
    
    private var timer: Timer?
    
    private init() {}
    
    func startMonitoring() {
        timer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { _ in
            self.updateHealthData()
        }
    }
    
    func stopMonitoring() {
        timer?.invalidate()
        timer = nil
    }
    
    private func updateHealthData() {
        // Simulate health data updates
        currentHeartRate = Double.random(in: 65...85)
        oxygenLevel = Double.random(in: 95...100)
        temperature = Double.random(in: 97.5...99.5)
    }
} 