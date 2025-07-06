import SwiftUI
import Charts

// MARK: - Interactive Chart Features
public struct InteractiveChartView<Content: View>: View {
    let content: Content
    @State private var selectedDate: Date?

    public init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    public var body: some View {
        VStack {
            content
                .chartOverlay {
                    GeometryReader { geometry in
                        Rectangle().fill(.clear).contentShape(Rectangle())
                            .gesture(
                                DragGesture()
                                    .onChanged { value in
                                        // Implement logic to find the nearest data point
                                        // and update the selectedDate state.
                                    }
                                    .onEnded { _ in
                                        selectedDate = nil
                                    }
                            )
                    }
                }
            
            if let selectedDate {
                Text("Selected: \(selectedDate, format: .dateTime)")
                    .padding()
                    .background(HealthAIDesignSystem.Color.surface)
                    .cornerRadius(10)
                    .transition(.opacity.animation(.easeInOut))
                    .accessibilityLabel("Selected date is \(selectedDate, format: .dateTime)")
            }
        }
    }
}

// MARK: - Interactive Chart Wrapper
public struct InteractiveChartWrapper<ChartContent: View>: View {
    let chartContent: ChartContent
    let onDataPointSelected: ((Point) -> Void)?
    let onChartTapped: (() -> Void)?
    let selectedPoint: Point?
    let showSelectionIndicator: Bool
    
    public init(
        @ViewBuilder chartContent: () -> ChartContent,
        onDataPointSelected: ((Point) -> Void)? = nil,
        onChartTapped: (() -> Void)? = nil,
        selectedPoint: Point? = nil,
        showSelectionIndicator: Bool = true
    ) {
        self.chartContent = chartContent()
        self.onDataPointSelected = onDataPointSelected
        self.onChartTapped = onChartTapped
        self.selectedPoint = selectedPoint
        self.showSelectionIndicator = showSelectionIndicator
    }
    
    public var body: some View {
        chartContent
            .chartOverlay { proxy in
                GeometryReader { geometry in
                    Rectangle()
                        .fill(.clear)
                        .contentShape(Rectangle())
                        .gesture(
                            DragGesture(minimumDistance: 0)
                                .onChanged { value in
                                    let location = value.location
                                    if let point = findClosestDataPoint(at: location, proxy: proxy, geometry: geometry) {
                                        onDataPointSelected?(point)
                                    }
                                }
                                .onEnded { _ in
                                    onChartTapped?()
                                }
                        )
                        .accessibilityAction(named: "Select Data Point") {
                            // Handle accessibility selection
                            if let point = selectedPoint {
                                onDataPointSelected?(point)
                            }
                        }
                }
            }
    }
    
    private func findClosestDataPoint(at location: CGPoint, proxy: ChartProxy, geometry: GeometryProxy) -> Point? {
        // This is a placeholder implementation
        // In a real implementation, you would use the proxy to find the closest data point
        return nil
    }
}

// MARK: - Zoomable Chart
public struct ZoomableChart<ChartContent: View>: View {
    let chartContent: ChartContent
    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero
    
    public init(@ViewBuilder chartContent: () -> ChartContent) {
        self.chartContent = chartContent()
    }
    
    public var body: some View {
        chartContent
            .scaleEffect(scale)
            .offset(offset)
            .gesture(
                SimultaneousGesture(
                    MagnificationGesture()
                        .onChanged { value in
                            let delta = value / lastScale
                            lastScale = value
                            scale = min(max(scale * delta, 0.5), 3.0)
                        }
                        .onEnded { _ in
                            lastScale = 1.0
                        },
                    DragGesture()
                        .onChanged { value in
                            let delta = CGSize(
                                width: value.translation.width - lastOffset.width,
                                height: value.translation.height - lastOffset.height
                            )
                            lastOffset = value.translation
                            offset = CGSize(
                                width: offset.width + delta.width,
                                height: offset.height + delta.height
                            )
                        }
                        .onEnded { _ in
                            lastOffset = .zero
                        }
                )
            )
            .accessibilityAction(named: "Reset Zoom") {
                withAnimation(.easeInOut(duration: 0.3)) {
                    scale = 1.0
                    offset = .zero
                }
            }
            .accessibilityHint(Text("Pinch to zoom, drag to pan, double tap to reset"))
    }
}

// MARK: - Chart Legend
public struct ChartLegend: View {
    let items: [LegendItem]
    let layout: LegendLayout
    
    public struct LegendItem {
        let label: String
        let color: Color
        let value: String?
        
        public init(label: String, color: Color, value: String? = nil) {
            self.label = label
            self.color = color
            self.value = value
        }
    }
    
    public enum LegendLayout {
        case horizontal, vertical, grid(columns: Int)
    }
    
    public init(items: [LegendItem], layout: LegendLayout = .horizontal) {
        self.items = items
        self.layout = layout
    }
    
    public var body: some View {
        Group {
            switch layout {
            case .horizontal:
                HStack(spacing: HealthAIDesignSystem.Spacing.medium) {
                    ForEach(items, id: \.label) { item in
                        LegendItemView(item: item)
                    }
                }
            case .vertical:
                VStack(alignment: .leading, spacing: HealthAIDesignSystem.Spacing.small) {
                    ForEach(items, id: \.label) { item in
                        LegendItemView(item: item)
                    }
                }
            case .grid(let columns):
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: columns), spacing: HealthAIDesignSystem.Spacing.small) {
                    ForEach(items, id: \.label) { item in
                        LegendItemView(item: item)
                    }
                }
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel(Text("Chart Legend"))
    }
}

private struct LegendItemView: View {
    let item: ChartLegend.LegendItem
    
    var body: some View {
        HStack(spacing: HealthAIDesignSystem.Spacing.small) {
            Circle()
                .fill(item.color)
                .frame(width: 12, height: 12)
            
            Text(item.label)
                .font(HealthAIDesignSystem.Typography.caption)
                .foregroundColor(HealthAIDesignSystem.Color.textPrimary)
            
            if let value = item.value {
                Text(value)
                    .font(HealthAIDesignSystem.Typography.caption)
                    .foregroundColor(HealthAIDesignSystem.Color.textSecondary)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Text("\(item.label): \(item.value ?? "")"))
    }
}

// MARK: - Chart Tooltip
public struct ChartTooltip: View {
    let point: Point
    let title: String?
    let formatter: ((Double) -> String)?
    let position: TooltipPosition
    
    public enum TooltipPosition {
        case top, bottom, left, right, center
    }
    
    public init(
        point: Point,
        title: String? = nil,
        formatter: ((Double) -> String)? = nil,
        position: TooltipPosition = .top
    ) {
        self.point = point
        self.title = title
        self.formatter = formatter
        self.position = position
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: HealthAIDesignSystem.Spacing.extraSmall) {
            if let title = title {
                Text(title)
                    .font(HealthAIDesignSystem.Typography.caption)
                    .fontWeight(.medium)
                    .foregroundColor(HealthAIDesignSystem.Color.textPrimary)
            }
            
            Text(formattedValue)
                .font(HealthAIDesignSystem.Typography.caption)
                .foregroundColor(HealthAIDesignSystem.Color.textSecondary)
            
            Text(formattedDate)
                .font(HealthAIDesignSystem.Typography.caption2)
                .foregroundColor(HealthAIDesignSystem.Color.textSecondary)
        }
        .padding(HealthAIDesignSystem.Spacing.small)
        .background(HealthAIDesignSystem.Color.surface)
        .cornerRadius(HealthAIDesignSystem.Layout.cornerRadius)
        .shadow(radius: HealthAIDesignSystem.Layout.shadowRadius)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Text("Tooltip: \(title ?? "") \(formattedValue) on \(formattedDate)"))
    }
    
    private var formattedValue: String {
        formatter?(point.value) ?? String(format: "%.1f", point.value)
    }
    
    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: point.date)
    }
}

// MARK: - Chart Selection Indicator
public struct ChartSelectionIndicator: View {
    let point: Point
    let color: Color
    let size: CGFloat
    
    public init(point: Point, color: Color = .red, size: CGFloat = 8) {
        self.point = point
        self.color = color
        self.size = size
    }
    
    public var body: some View {
        Circle()
            .fill(color)
            .frame(width: size, height: size)
            .overlay(
                Circle()
                    .stroke(Color.white, lineWidth: 2)
            )
            .shadow(radius: 2)
            .accessibilityHidden(true)
    }
}

// MARK: - Chart Accessibility Helper
public struct ChartAccessibilityHelper {
    public static func generateAccessibilityLabel(for data: [Point], title: String? = nil) -> String {
        let titleText = title ?? "Chart"
        let count = data.count
        
        guard !data.isEmpty else {
            return "\(titleText) with no data"
        }
        
        let minValue = data.map { $0.value }.min() ?? 0
        let maxValue = data.map { $0.value }.max() ?? 0
        let avgValue = data.map { $0.value }.reduce(0, +) / Double(data.count)
        
        return "\(titleText) showing \(count) data points. Values range from \(String(format: "%.1f", minValue)) to \(String(format: "%.1f", maxValue)) with an average of \(String(format: "%.1f", avgValue))"
    }
    
    public static func generateAccessibilityValue(for data: [Point]) -> String {
        guard !data.isEmpty else { return "No data available" }
        
        let latestValue = data.last?.value ?? 0
        let trend = calculateTrend(data: data)
        
        return "Latest value is \(String(format: "%.1f", latestValue)). \(trend)"
    }
    
    private static func calculateTrend(data: [Point]) -> String {
        guard data.count >= 2 else { return "Insufficient data for trend analysis" }
        
        let sortedData = data.sorted { $0.date < $1.date }
        let firstValue = sortedData.first?.value ?? 0
        let lastValue = sortedData.last?.value ?? 0
        
        if lastValue > firstValue {
            return "Trend is increasing"
        } else if lastValue < firstValue {
            return "Trend is decreasing"
        } else {
            return "Trend is stable"
        }
    }
}

// MARK: - Chart Gesture Recognizer
public struct ChartGestureRecognizer: ViewModifier {
    let onTap: (() -> Void)?
    let onLongPress: (() -> Void)?
    let onDrag: ((DragGesture.Value) -> Void)?
    
    public init(
        onTap: (() -> Void)? = nil,
        onLongPress: (() -> Void)? = nil,
        onDrag: ((DragGesture.Value) -> Void)? = nil
    ) {
        self.onTap = onTap
        self.onLongPress = onLongPress
        self.onDrag = onDrag
    }
    
    public func body(content: Content) -> some View {
        content
            .gesture(
                SimultaneousGesture(
                    TapGesture()
                        .onEnded { _ in
                            onTap?()
                        },
                    LongPressGesture(minimumDuration: 0.5)
                        .onEnded { _ in
                            onLongPress?()
                        }
                )
            )
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        onDrag?(value)
                    }
            )
    }
}

// MARK: - Chart Focus Manager
public class ChartFocusManager: ObservableObject {
    @Published public var focusedPoint: Point?
    @Published public var isFocused: Bool = false
    
    public func focus(on point: Point?) {
        focusedPoint = point
        isFocused = point != nil
    }
    
    public func clearFocus() {
        focusedPoint = nil
        isFocused = false
    }
}

// MARK: - Chart Animation Helper
public struct ChartAnimationHelper {
    public static func animateChart<T: View>(_ content: T, delay: Double = 0.0) -> some View {
        content
            .opacity(0)
            .scaleEffect(0.8)
            .onAppear {
                withAnimation(.easeOut(duration: 0.6).delay(delay)) {
                    // Animation will be applied through state changes
                }
            }
    }
    
    public static func animateDataPoint<T: View>(_ content: T, delay: Double = 0.0) -> some View {
        content
            .scaleEffect(0)
            .onAppear {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(delay)) {
                    // Animation will be applied through state changes
                }
            }
    }
}
