import SwiftUI

// MARK: - Card Types
public enum CardType {
    case standard
    case elevated
    case outlined
    case healthMetric
    case medical
    case interactive
}

// MARK: - HealthAI Card
public struct HealthAICard<Content: View>: View {
    let type: CardType
    let content: Content
    let padding: CGFloat
    let cornerRadius: CGFloat
    let shadowRadius: CGFloat
    let onTap: (() -> Void)?
    
    public init(
        type: CardType = .standard,
        padding: CGFloat = SpacingGrid.cardPadding,
        cornerRadius: CGFloat = SpacingGrid.medium,
        shadowRadius: CGFloat = SpacingGrid.small,
        onTap: (() -> Void)? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.type = type
        self.padding = padding
        self.cornerRadius = cornerRadius
        self.shadowRadius = shadowRadius
        self.onTap = onTap
        self.content = content()
    }
    
    public var body: some View {
        Group {
            if let onTap = onTap {
                Button(action: onTap) {
                    cardContent
                }
                .buttonStyle(PlainButtonStyle())
            } else {
                cardContent
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel(Text("Card"))
        .accessibilityAddTraits(onTap != nil ? .isButton : [])
    }
    
    private var cardContent: some View {
        content
            .padding(padding)
            .background(backgroundColor)
            .cornerRadius(cornerRadius)
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(borderColor, lineWidth: borderWidth)
            )
            .shadow(color: shadowColor, radius: shadowRadius, x: 0, y: shadowYOffset)
    }
    
    // MARK: - Style Properties
    private var backgroundColor: Color {
        switch type {
        case .standard:
            return ColorPalette.cardBackground
        case .elevated:
            return ColorPalette.background
        case .outlined:
            return ColorPalette.background
        case .healthMetric:
            return ColorPalette.healthPrimary.opacity(0.05)
        case .medical:
            return ColorPalette.healthSecondary.opacity(0.05)
        case .interactive:
            return ColorPalette.cardBackground
        }
    }
    
    private var borderColor: Color {
        switch type {
        case .standard:
            return Color.clear
        case .elevated:
            return Color.clear
        case .outlined:
            return ColorPalette.border
        case .healthMetric:
            return ColorPalette.healthPrimary.opacity(0.2)
        case .medical:
            return ColorPalette.healthSecondary.opacity(0.2)
        case .interactive:
            return ColorPalette.primary.opacity(0.2)
        }
    }
    
    private var borderWidth: CGFloat {
        switch type {
        case .outlined, .healthMetric, .medical, .interactive:
            return 1
        default:
            return 0
        }
    }
    
    private var shadowColor: Color {
        switch type {
        case .elevated:
            return Color.black.opacity(0.15)
        case .interactive:
            return Color.black.opacity(0.1)
        default:
            return Color.black.opacity(0.05)
        }
    }
    
    private var shadowYOffset: CGFloat {
        switch type {
        case .elevated:
            return 4
        case .interactive:
            return 2
        default:
            return 1
        }
    }
}

// MARK: - Health Metric Card
public struct HealthMetricCard: View {
    let title: String
    let value: String
    let unit: String?
    let trend: String?
    let icon: String
    let color: Color
    let isAnimated: Bool
    let onTap: (() -> Void)?
    
    @State private var isAnimating: Bool = false
    
    public init(
        title: String,
        value: String,
        unit: String? = nil,
        trend: String? = nil,
        icon: String,
        color: Color,
        isAnimated: Bool = false,
        onTap: (() -> Void)? = nil
    ) {
        self.title = title
        self.value = value
        self.unit = unit
        self.trend = trend
        self.icon = icon
        self.color = color
        self.isAnimated = isAnimated
        self.onTap = onTap
    }
    
    public var body: some View {
        HealthAICard(type: .healthMetric, onTap: onTap) {
            VStack(alignment: .leading, spacing: SpacingGrid.medium) {
                // Header
                HStack {
                    Image(systemName: icon)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(color)
                        .scaleEffect(isAnimating ? 1.1 : 1.0)
                    
                    Spacer()
                    
                    if let trend = trend {
                        Text(trend)
                            .font(TypographySystem.caption)
                            .foregroundColor(trendColor)
                            .padding(.horizontal, SpacingGrid.small)
                            .padding(.vertical, 2)
                            .background(trendBackgroundColor)
                            .cornerRadius(SpacingGrid.small)
                    }
                }
                
                // Value
                HStack(alignment: .bottom, spacing: SpacingGrid.small) {
                    Text(value)
                        .font(TypographySystem.healthMetricMedium)
                        .fontWeight(.bold)
                        .foregroundColor(ColorPalette.textPrimary)
                    
                    if let unit = unit {
                        Text(unit)
                            .font(TypographySystem.healthMetricUnit)
                            .foregroundColor(ColorPalette.textSecondary)
                    }
                }
                
                // Title
                Text(title)
                    .font(TypographySystem.healthMetricLabel)
                    .foregroundColor(ColorPalette.textSecondary)
            }
        }
        .onAppear {
            if isAnimated {
                withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
                    isAnimating = true
                }
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Text(accessibilityLabel))
        .accessibilityHint(Text(accessibilityHint))
    }
    
    private var trendColor: Color {
        if trend?.contains("+") == true {
            return ColorPalette.success
        } else if trend?.contains("-") == true {
            return ColorPalette.critical
        }
        return ColorPalette.textSecondary
    }
    
    private var trendBackgroundColor: Color {
        if trend?.contains("+") == true {
            return ColorPalette.success.opacity(0.1)
        } else if trend?.contains("-") == true {
            return ColorPalette.critical.opacity(0.1)
        }
        return ColorPalette.surface
    }
    
    private var accessibilityLabel: String {
        var label = "\(title): \(value)"
        if let unit = unit {
            label += " \(unit)"
        }
        if let trend = trend {
            label += ", \(trend)"
        }
        return label
    }
    
    private var accessibilityHint: String {
        return onTap != nil ? "Double tap to view details" : ""
    }
}

// MARK: - Medical Data Card
public struct MedicalDataCard: View {
    let title: String
    let data: [MedicalDataItem]
    let icon: String
    let color: Color
    let onTap: (() -> Void)?
    
    public init(
        title: String,
        data: [MedicalDataItem],
        icon: String,
        color: Color,
        onTap: (() -> Void)? = nil
    ) {
        self.title = title
        self.data = data
        self.icon = icon
        self.color = color
        self.onTap = onTap
    }
    
    public var body: some View {
        HealthAICard(type: .medical, onTap: onTap) {
            VStack(alignment: .leading, spacing: SpacingGrid.medium) {
                // Header
                HStack {
                    Image(systemName: icon)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(color)
                    
                    Text(title)
                        .font(TypographySystem.medicalLabel)
                        .fontWeight(.semibold)
                        .foregroundColor(ColorPalette.textPrimary)
                    
                    Spacer()
                }
                
                // Data Items
                VStack(spacing: SpacingGrid.small) {
                    ForEach(data, id: \.label) { item in
                        HStack {
                            Text(item.label)
                                .font(TypographySystem.medicalCaption)
                                .foregroundColor(ColorPalette.textSecondary)
                            
                            Spacer()
                            
                            Text(item.value)
                                .font(TypographySystem.medicalReading)
                                .foregroundColor(ColorPalette.textPrimary)
                        }
                    }
                }
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel(Text(accessibilityLabel))
        .accessibilityHint(Text(accessibilityHint))
    }
    
    private var accessibilityLabel: String {
        return "\(title): \(data.map { "\($0.label) \($0.value)" }.joined(separator: ", "))"
    }
    
    private var accessibilityHint: String {
        return onTap != nil ? "Double tap to view details" : ""
    }
}

// MARK: - Medical Data Item
public struct MedicalDataItem {
    let label: String
    let value: String
    
    public init(label: String, value: String) {
        self.label = label
        self.value = value
    }
}

// MARK: - List Components

/// Health data list item
public struct HealthDataListItem: View {
    let title: String
    let subtitle: String?
    let value: String?
    let icon: String?
    let color: Color?
    let isSelected: Bool
    let onTap: (() -> Void)?
    
    public init(
        title: String,
        subtitle: String? = nil,
        value: String? = nil,
        icon: String? = nil,
        color: Color? = nil,
        isSelected: Bool = false,
        onTap: (() -> Void)? = nil
    ) {
        self.title = title
        self.subtitle = subtitle
        self.value = value
        self.icon = icon
        self.color = color
        self.isSelected = false
        self.onTap = onTap
    }
    
    public var body: some View {
        Group {
            if let onTap = onTap {
                Button(action: onTap) {
                    listItemContent
                }
                .buttonStyle(PlainButtonStyle())
            } else {
                listItemContent
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Text(accessibilityLabel))
        .accessibilityHint(Text(accessibilityHint))
        .accessibilityAddTraits(onTap != nil ? .isButton : [])
    }
    
    private var listItemContent: some View {
        HStack(spacing: SpacingGrid.medium) {
            if let icon = icon {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(iconColor)
                    .frame(width: 24)
            }
            
            VStack(alignment: .leading, spacing: SpacingGrid.small) {
                Text(title)
                    .font(TypographySystem.body)
                    .fontWeight(.medium)
                    .foregroundColor(ColorPalette.textPrimary)
                
                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(TypographySystem.caption)
                        .foregroundColor(ColorPalette.textSecondary)
                }
            }
            
            Spacer()
            
            if let value = value {
                Text(value)
                    .font(TypographySystem.body)
                    .fontWeight(.semibold)
                    .foregroundColor(ColorPalette.textPrimary)
            }
            
            if onTap != nil {
                Image(systemName: "chevron.right")
                    .font(.system(size: 12))
                    .foregroundColor(ColorPalette.textSecondary)
            }
        }
        .padding(SpacingGrid.listRowPadding)
        .background(isSelected ? ColorPalette.primary.opacity(0.1) : Color.clear)
        .cornerRadius(SpacingGrid.small)
    }
    
    private var iconColor: Color {
        return color ?? ColorPalette.textSecondary
    }
    
    private var accessibilityLabel: String {
        var label = title
        if let subtitle = subtitle {
            label += ", \(subtitle)"
        }
        if let value = value {
            label += ", \(value)"
        }
        if isSelected {
            label += ", selected"
        }
        return label
    }
    
    private var accessibilityHint: String {
        return onTap != nil ? "Double tap to select" : ""
    }
}

// MARK: - Table Components

/// Simple data table
public struct HealthDataTable: View {
    let headers: [String]
    let rows: [[String]]
    let onRowTap: ((Int) -> Void)?
    
    public init(headers: [String], rows: [[String]], onRowTap: ((Int) -> Void)? = nil) {
        self.headers = headers
        self.rows = rows
        self.onRowTap = onRowTap
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            // Headers
            HStack(spacing: 0) {
                ForEach(headers, id: \.self) { header in
                    Text(header)
                        .font(TypographySystem.caption.weight(.semibold))
                        .foregroundColor(ColorPalette.textPrimary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(SpacingGrid.small)
                        .background(ColorPalette.surface)
                }
            }
            
            // Rows
            ForEach(Array(rows.enumerated()), id: \.offset) { index, row in
                HStack(spacing: 0) {
                    ForEach(Array(row.enumerated()), id: \.offset) { cellIndex, cell in
                        Text(cell)
                            .font(TypographySystem.caption)
                            .foregroundColor(ColorPalette.textSecondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(SpacingGrid.small)
                    }
                }
                .background(index % 2 == 0 ? ColorPalette.background : ColorPalette.surface)
                .onTapGesture {
                    onRowTap?(index)
                }
            }
        }
        .background(ColorPalette.border)
        .cornerRadius(SpacingGrid.small)
        .accessibilityElement(children: .contain)
        .accessibilityLabel(Text("Data table with \(rows.count) rows"))
    }
}

// MARK: - Chart Components

/// Simple bar chart
public struct SimpleBarChart: View {
    let data: [ChartDataPoint]
    let title: String
    let color: Color
    
    public init(data: [ChartDataPoint], title: String, color: Color = ColorPalette.primary) {
        self.data = data
        self.title = title
        self.color = color
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: SpacingGrid.medium) {
            Text(title)
                .font(TypographySystem.headline)
                .fontWeight(.semibold)
                .foregroundColor(ColorPalette.textPrimary)
            
            HStack(alignment: .bottom, spacing: SpacingGrid.small) {
                ForEach(data, id: \.label) { point in
                    VStack(spacing: SpacingGrid.small) {
                        Rectangle()
                            .fill(color)
                            .frame(height: max(20, CGFloat(point.value) * 100))
                            .cornerRadius(SpacingGrid.small)
                        
                        Text(point.label)
                            .font(TypographySystem.caption2)
                            .foregroundColor(ColorPalette.textSecondary)
                            .rotationEffect(.degrees(-45))
                    }
                }
            }
            .frame(height: 120)
        }
        .padding(SpacingGrid.medium)
        .background(ColorPalette.cardBackground)
        .cornerRadius(SpacingGrid.medium)
        .accessibilityElement(children: .contain)
        .accessibilityLabel(Text("\(title) chart with \(data.count) data points"))
    }
}

// MARK: - Chart Data Point
public struct ChartDataPoint {
    let label: String
    let value: Double
    
    public init(label: String, value: Double) {
        self.label = label
        self.value = value
    }
}

// MARK: - Data Display Extensions

extension View {
    /// Apply card styling
    public func cardStyle(_ type: CardType = .standard) -> some View {
        self.background(ColorPalette.cardBackground)
            .cornerRadius(SpacingGrid.medium)
            .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
    
    /// Apply list item styling
    public func listItemStyle() -> some View {
        self.padding(SpacingGrid.listRowPadding)
            .background(ColorPalette.background)
            .cornerRadius(SpacingGrid.small)
    }
} 