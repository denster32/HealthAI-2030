import SwiftUI

// MARK: - Navigation Tab Item
public struct NavigationTabItem: Identifiable, Hashable {
    public let id = UUID()
    public let title: String
    public let icon: String
    public let badge: String?
    public let isEnabled: Bool
    
    public init(title: String, icon: String, badge: String? = nil, isEnabled: Bool = true) {
        self.title = title
        self.icon = icon
        self.badge = badge
        self.isEnabled = isEnabled
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    public static func == (lhs: NavigationTabItem, rhs: NavigationTabItem) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - HealthAI Tab Bar
public struct HealthAITabBar: View {
    let items: [NavigationTabItem]
    @Binding var selectedTab: Int
    
    public init(items: [NavigationTabItem], selectedTab: Binding<Int>) {
        self.items = items
        self._selectedTab = selectedTab
    }
    
    public var body: some View {
        HStack(spacing: 0) {
            ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                TabBarItem(
                    item: item,
                    isSelected: selectedTab == index,
                    action: {
                        if item.isEnabled {
                            selectedTab = index
                        }
                    }
                )
            }
        }
        .background(ColorPalette.background)
        .overlay(
            Rectangle()
                .frame(height: 0.5)
                .foregroundColor(ColorPalette.border),
            alignment: .top
        )
        .accessibilityElement(children: .contain)
        .accessibilityLabel(Text("Tab bar with \(items.count) tabs"))
    }
}

// MARK: - Tab Bar Item
private struct TabBarItem: View {
    let item: NavigationTabItem
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: SpacingGrid.small) {
                ZStack {
                    Image(systemName: item.icon)
                        .font(.system(size: 20, weight: isSelected ? .semibold : .regular))
                        .foregroundColor(iconColor)
                    
                    if let badge = item.badge {
                        Text(badge)
                            .font(TypographySystem.caption2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .padding(.horizontal, 4)
                            .padding(.vertical, 2)
                            .background(ColorPalette.critical)
                            .clipShape(Capsule())
                            .offset(x: 12, y: -12)
                    }
                }
                
                Text(item.title)
                    .font(TypographySystem.caption)
                    .fontWeight(isSelected ? .semibold : .regular)
                    .foregroundColor(textColor)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, SpacingGrid.small)
        }
        .disabled(!item.isEnabled)
        .opacity(item.isEnabled ? 1.0 : 0.5)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Text(accessibilityLabel))
        .accessibilityHint(Text(accessibilityHint))
        .accessibilityAddTraits(.isButton)
    }
    
    private var iconColor: Color {
        if !item.isEnabled {
            return ColorPalette.textSecondary
        }
        return isSelected ? ColorPalette.primary : ColorPalette.textSecondary
    }
    
    private var textColor: Color {
        if !item.isEnabled {
            return ColorPalette.textSecondary
        }
        return isSelected ? ColorPalette.primary : ColorPalette.textSecondary
    }
    
    private var accessibilityLabel: String {
        var label = item.title
        if isSelected {
            label += ", selected"
        }
        if !item.isEnabled {
            label += ", disabled"
        }
        if let badge = item.badge {
            label += ", \(badge) notifications"
        }
        return label
    }
    
    private var accessibilityHint: String {
        if !item.isEnabled {
            return "Tab is disabled"
        }
        return "Double tap to select \(item.title.lowercased()) tab"
    }
}

// MARK: - Breadcrumb Item
public struct BreadcrumbItem: Identifiable, Hashable {
    public let id = UUID()
    public let title: String
    public let icon: String?
    public let action: (() -> Void)?
    
    public init(title: String, icon: String? = nil, action: (() -> Void)? = nil) {
        self.title = title
        self.icon = icon
        self.action = action
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    public static func == (lhs: BreadcrumbItem, rhs: BreadcrumbItem) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - HealthAI Breadcrumbs
public struct HealthAIBreadcrumbs: View {
    let items: [BreadcrumbItem]
    
    public init(items: [BreadcrumbItem]) {
        self.items = items
    }
    
    public var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: SpacingGrid.small) {
                ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                    HStack(spacing: SpacingGrid.small) {
                        if let action = item.action {
                            Button(action: action) {
                                breadcrumbContent(item)
                            }
                            .accessibilityLabel(Text("Navigate to \(item.title)"))
                        } else {
                            breadcrumbContent(item)
                        }
                        
                        if index < items.count - 1 {
                            Image(systemName: "chevron.right")
                                .font(.system(size: 12))
                                .foregroundColor(ColorPalette.textSecondary)
                        }
                    }
                }
            }
            .padding(.horizontal, SpacingGrid.medium)
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel(Text("Breadcrumb navigation"))
    }
    
    private func breadcrumbContent(_ item: BreadcrumbItem) -> some View {
        HStack(spacing: SpacingGrid.small) {
            if let icon = item.icon {
                Image(systemName: icon)
                    .font(.system(size: 14))
                    .foregroundColor(ColorPalette.textSecondary)
            }
            
            Text(item.title)
                .font(TypographySystem.caption)
                .foregroundColor(item.action != nil ? ColorPalette.primary : ColorPalette.textSecondary)
        }
        .padding(.vertical, SpacingGrid.small)
        .padding(.horizontal, SpacingGrid.medium)
        .background(item.action != nil ? ColorPalette.primary.opacity(0.1) : Color.clear)
        .cornerRadius(SpacingGrid.small)
    }
}

// MARK: - Pagination Item
public struct PaginationItem: Identifiable {
    public let id = UUID()
    public let page: Int
    public let isCurrent: Bool
    public let isEnabled: Bool
    public let action: () -> Void
    
    public init(page: Int, isCurrent: Bool, isEnabled: Bool = true, action: @escaping () -> Void) {
        self.page = page
        self.isCurrent = isCurrent
        self.isEnabled = isEnabled
        self.action = action
    }
}

// MARK: - HealthAI Pagination
public struct HealthAIPagination: View {
    let currentPage: Int
    let totalPages: Int
    let onPageChange: (Int) -> Void
    let showFirstLast: Bool
    
    public init(
        currentPage: Int,
        totalPages: Int,
        onPageChange: @escaping (Int) -> Void,
        showFirstLast: Bool = true
    ) {
        self.currentPage = currentPage
        self.totalPages = totalPages
        self.onPageChange = onPageChange
        self.showFirstLast = showFirstLast
    }
    
    public var body: some View {
        HStack(spacing: SpacingGrid.small) {
            // First page button
            if showFirstLast && currentPage > 1 {
                Button(action: { onPageChange(1) }) {
                    Image(systemName: "chevron.left.2")
                        .font(.system(size: 14))
                        .foregroundColor(ColorPalette.primary)
                }
                .accessibilityLabel(Text("Go to first page"))
            }
            
            // Previous page button
            if currentPage > 1 {
                Button(action: { onPageChange(currentPage - 1) }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 14))
                        .foregroundColor(ColorPalette.primary)
                }
                .accessibilityLabel(Text("Go to previous page"))
            }
            
            // Page numbers
            ForEach(visiblePages, id: \.self) { page in
                Button(action: { onPageChange(page) }) {
                    Text("\(page)")
                        .font(TypographySystem.body)
                        .fontWeight(page == currentPage ? .semibold : .regular)
                        .foregroundColor(page == currentPage ? .white : ColorPalette.textPrimary)
                        .frame(width: 32, height: 32)
                        .background(page == currentPage ? ColorPalette.primary : ColorPalette.background)
                        .cornerRadius(SpacingGrid.small)
                        .overlay(
                            RoundedRectangle(cornerRadius: SpacingGrid.small)
                                .stroke(ColorPalette.border, lineWidth: 1)
                        )
                }
                .accessibilityLabel(Text("Go to page \(page)"))
                .accessibilityAddTraits(page == currentPage ? [.isSelected] : [])
            }
            
            // Next page button
            if currentPage < totalPages {
                Button(action: { onPageChange(currentPage + 1) }) {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14))
                        .foregroundColor(ColorPalette.primary)
                }
                .accessibilityLabel(Text("Go to next page"))
            }
            
            // Last page button
            if showFirstLast && currentPage < totalPages {
                Button(action: { onPageChange(totalPages) }) {
                    Image(systemName: "chevron.right.2")
                        .font(.system(size: 14))
                        .foregroundColor(ColorPalette.primary)
                }
                .accessibilityLabel(Text("Go to last page"))
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel(Text("Pagination: page \(currentPage) of \(totalPages)"))
    }
    
    private var visiblePages: [Int] {
        let maxVisible = 5
        var pages: [Int] = []
        
        if totalPages <= maxVisible {
            pages = Array(1...totalPages)
        } else {
            let start = max(1, currentPage - 2)
            let end = min(totalPages, start + maxVisible - 1)
            
            if end - start < maxVisible - 1 {
                let adjustedStart = max(1, end - maxVisible + 1)
                pages = Array(adjustedStart...end)
            } else {
                pages = Array(start...end)
            }
        }
        
        return pages
    }
}

// MARK: - Health-Specific Navigation Components

/// Navigation for health categories
public struct HealthCategoryNavigation: View {
    let categories: [HealthCategory]
    @Binding var selectedCategory: HealthCategory?
    
    public init(categories: [HealthCategory], selectedCategory: Binding<HealthCategory?>) {
        self.categories = categories
        self._selectedCategory = selectedCategory
    }
    
    public var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: SpacingGrid.medium) {
                ForEach(categories, id: \.self) { category in
                    HealthCategoryButton(
                        category: category,
                        isSelected: selectedCategory == category,
                        action: { selectedCategory = category }
                    )
                }
            }
            .padding(.horizontal, SpacingGrid.medium)
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel(Text("Health category navigation"))
    }
}

/// Health category button
private struct HealthCategoryButton: View {
    let category: HealthCategory
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: SpacingGrid.small) {
                Image(systemName: category.icon)
                    .font(.system(size: 24, weight: isSelected ? .semibold : .regular))
                    .foregroundColor(iconColor)
                
                Text(category.title)
                    .font(TypographySystem.caption)
                    .fontWeight(isSelected ? .semibold : .regular)
                    .foregroundColor(textColor)
                    .multilineTextAlignment(.center)
            }
            .frame(width: 80, height: 80)
            .background(backgroundColor)
            .cornerRadius(SpacingGrid.medium)
            .overlay(
                RoundedRectangle(cornerRadius: SpacingGrid.medium)
                    .stroke(borderColor, lineWidth: borderWidth)
            )
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Text(accessibilityLabel))
        .accessibilityHint(Text("Double tap to select \(category.title.lowercased())"))
        .accessibilityAddTraits(.isButton)
    }
    
    private var backgroundColor: Color {
        return isSelected ? ColorPalette.forHealthMetric(category.metricType).opacity(0.1) : ColorPalette.background
    }
    
    private var borderColor: Color {
        return isSelected ? ColorPalette.forHealthMetric(category.metricType) : ColorPalette.border
    }
    
    private var borderWidth: CGFloat {
        return isSelected ? 2 : 1
    }
    
    private var iconColor: Color {
        return isSelected ? ColorPalette.forHealthMetric(category.metricType) : ColorPalette.textSecondary
    }
    
    private var textColor: Color {
        return isSelected ? ColorPalette.forHealthMetric(category.metricType) : ColorPalette.textSecondary
    }
    
    private var accessibilityLabel: String {
        return isSelected ? "\(category.title), selected" : category.title
    }
}

/// Medical navigation for patient records
public struct MedicalNavigation: View {
    let sections: [MedicalSection]
    @Binding var selectedSection: MedicalSection?
    
    public init(sections: [MedicalSection], selectedSection: Binding<MedicalSection?>) {
        self.sections = sections
        self._selectedSection = selectedSection
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            ForEach(sections, id: \.self) { section in
                MedicalSectionButton(
                    section: section,
                    isSelected: selectedSection == section,
                    action: { selectedSection = section }
                )
            }
        }
        .background(ColorPalette.secondaryBackground)
        .cornerRadius(SpacingGrid.medium)
        .accessibilityElement(children: .contain)
        .accessibilityLabel(Text("Medical navigation"))
    }
}

/// Medical section button
private struct MedicalSectionButton: View {
    let section: MedicalSection
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: SpacingGrid.medium) {
                Image(systemName: section.icon)
                    .font(.system(size: 18, weight: isSelected ? .semibold : .regular))
                    .foregroundColor(iconColor)
                    .frame(width: 24)
                
                Text(section.title)
                    .font(TypographySystem.medicalLabel)
                    .fontWeight(isSelected ? .semibold : .regular)
                    .foregroundColor(textColor)
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12))
                        .foregroundColor(ColorPalette.primary)
                }
            }
            .padding(SpacingGrid.medium)
            .background(backgroundColor)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Text(accessibilityLabel))
        .accessibilityHint(Text("Double tap to view \(section.title.lowercased())"))
        .accessibilityAddTraits(.isButton)
    }
    
    private var backgroundColor: Color {
        return isSelected ? ColorPalette.primary.opacity(0.1) : Color.clear
    }
    
    private var iconColor: Color {
        return isSelected ? ColorPalette.primary : ColorPalette.textSecondary
    }
    
    private var textColor: Color {
        return isSelected ? ColorPalette.primary : ColorPalette.textPrimary
    }
    
    private var accessibilityLabel: String {
        return isSelected ? "\(section.title), selected" : section.title
    }
}

// MARK: - Supporting Enums

/// Health categories for navigation
public enum HealthCategory: String, CaseIterable {
    case heartRate = "Heart Rate"
    case bloodPressure = "Blood Pressure"
    case temperature = "Temperature"
    case oxygen = "Oxygen"
    case sleep = "Sleep"
    case activity = "Activity"
    case nutrition = "Nutrition"
    case mentalHealth = "Mental Health"
    
    var title: String {
        return self.rawValue
    }
    
    var icon: String {
        switch self {
        case .heartRate:
            return "heart.fill"
        case .bloodPressure:
            return "drop.fill"
        case .temperature:
            return "thermometer"
        case .oxygen:
            return "lungs.fill"
        case .sleep:
            return "bed.double.fill"
        case .activity:
            return "figure.walk"
        case .nutrition:
            return "leaf.fill"
        case .mentalHealth:
            return "brain.head.profile"
        }
    }
    
    var metricType: HealthMetricType {
        switch self {
        case .heartRate:
            return .heartRate
        case .bloodPressure:
            return .bloodPressure
        case .temperature:
            return .temperature
        case .oxygen:
            return .oxygen
        case .sleep:
            return .sleep
        case .activity:
            return .activity
        case .nutrition:
            return .nutrition
        case .mentalHealth:
            return .mentalHealth
        }
    }
}

/// Medical sections for navigation
public enum MedicalSection: String, CaseIterable {
    case patientInfo = "Patient Information"
    case vitals = "Vital Signs"
    case medications = "Medications"
    case allergies = "Allergies"
    case labResults = "Lab Results"
    case procedures = "Procedures"
    case notes = "Clinical Notes"
    
    var title: String {
        return self.rawValue
    }
    
    var icon: String {
        switch self {
        case .patientInfo:
            return "person.fill"
        case .vitals:
            return "heart.fill"
        case .medications:
            return "pills.fill"
        case .allergies:
            return "exclamationmark.triangle.fill"
        case .labResults:
            return "testtube.2"
        case .procedures:
            return "stethoscope"
        case .notes:
            return "note.text"
        }
    }
}

// MARK: - Navigation Extensions

extension View {
    /// Apply navigation bar styling
    public func healthNavigationBar() -> some View {
        self.navigationBarTitleDisplayMode(.large)
            .navigationBarBackButtonHidden(false)
    }
    
    /// Apply tab bar styling
    public func healthTabBar() -> some View {
        self.tabBarAppearance()
    }
}

// MARK: - Tab Bar Appearance
private extension View {
    func tabBarAppearance() -> some View {
        self.onAppear {
            let appearance = UITabBarAppearance()
            appearance.configureWithOpaqueBackground()
            appearance.backgroundColor = UIColor(ColorPalette.background)
            
            UITabBar.appearance().standardAppearance = appearance
            UITabBar.appearance().scrollEdgeAppearance = appearance
        }
    }
} 