import SwiftUI
import Charts

/// Advanced Analytics Dashboard View
/// Provides a comprehensive analytics dashboard with customizable widgets,
/// advanced filtering, comparison tools, and export features
struct AdvancedAnalyticsDashboardView: View {
    
    // MARK: - Properties
    
    @StateObject private var dashboardManager: AdvancedAnalyticsDashboardManager
    @State private var showingAddWidget = false
    @State private var showingFilters = false
    @State private var showingComparison = false
    @State private var showingExport = false
    @State private var selectedWidget: DashboardWidget?
    @State private var isEditingLayout = false
    
    // MARK: - Initialization
    
    init(healthDataManager: HealthDataManager, analyticsEngine: AnalyticsEngine, mlModelManager: MLModelManager) {
        self._dashboardManager = StateObject(wrappedValue: AdvancedAnalyticsDashboardManager(
            healthDataManager: healthDataManager,
            analyticsEngine: analyticsEngine,
            mlModelManager: mlModelManager
        ))
    }
    
    // MARK: - Body
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header with controls
                dashboardHeader
                
                // Main dashboard content
                dashboardContent
            }
            .navigationTitle("Analytics Dashboard")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    dashboardToolbar
                }
            }
            .sheet(isPresented: $showingAddWidget) {
                AddWidgetView(dashboardManager: dashboardManager)
            }
            .sheet(isPresented: $showingFilters) {
                FilterView(dashboardManager: dashboardManager)
            }
            .sheet(isPresented: $showingComparison) {
                ComparisonView(dashboardManager: dashboardManager)
            }
            .sheet(isPresented: $showingExport) {
                ExportView(dashboardManager: dashboardManager)
            }
            .onAppear {
                dashboardManager.loadDashboardLayout()
                dashboardManager.refreshDashboard()
            }
        }
    }
    
    // MARK: - Header
    
    private var dashboardHeader: some View {
        VStack(spacing: 12) {
            // Time range selector
            HStack {
                Text("Time Range:")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Picker("Time Range", selection: $dashboardManager.selectedTimeRange) {
                    ForEach(TimeRange.allCases, id: \.self) { range in
                        Text(range.displayName).tag(range)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .onChange(of: dashboardManager.selectedTimeRange) { _ in
                    dashboardManager.refreshDashboard()
                }
                
                Spacer()
                
                Button(action: {
                    dashboardManager.refreshDashboard()
                }) {
                    Image(systemName: "arrow.clockwise")
                        .foregroundColor(.blue)
                }
                .disabled(dashboardManager.isLoading)
            }
            .padding(.horizontal)
            
            // Active filters display
            if !dashboardManager.activeFilters.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(dashboardManager.activeFilters.indices, id: \.self) { index in
                            FilterChip(filter: dashboardManager.activeFilters[index]) {
                                dashboardManager.activeFilters.remove(at: index)
                                dashboardManager.refreshDashboard()
                            }
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
        .padding(.vertical, 8)
        .background(Color(.systemGroupedBackground))
    }
    
    // MARK: - Dashboard Content
    
    private var dashboardContent: some View {
        ScrollView {
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 2), spacing: 12) {
                ForEach(dashboardManager.dashboardWidgets) { widget in
                    DashboardWidgetView(
                        widget: widget,
                        isEditing: isEditingLayout,
                        onRemove: {
                            dashboardManager.removeWidget(id: widget.id)
                        },
                        onTap: {
                            selectedWidget = widget
                        }
                    )
                    .frame(height: widget.size.height * 200)
                }
            }
            .padding()
        }
        .refreshable {
            dashboardManager.refreshDashboard()
        }
    }
    
    // MARK: - Toolbar
    
    private var dashboardToolbar: some View {
        HStack(spacing: 16) {
            Button(action: { showingFilters.toggle() }) {
                Image(systemName: "line.3.horizontal.decrease.circle")
                    .foregroundColor(dashboardManager.activeFilters.isEmpty ? .gray : .blue)
            }
            
            Button(action: { showingComparison.toggle() }) {
                Image(systemName: "chart.bar.xaxis")
                    .foregroundColor(dashboardManager.comparisonMode == .none ? .gray : .blue)
            }
            
            Button(action: { showingAddWidget.toggle() }) {
                Image(systemName: "plus.circle")
                    .foregroundColor(.blue)
            }
            
            Button(action: { isEditingLayout.toggle() }) {
                Image(systemName: isEditingLayout ? "checkmark.circle" : "pencil.circle")
                    .foregroundColor(isEditingLayout ? .green : .blue)
            }
            
            Menu {
                Button("Export as CSV") {
                    showingExport = true
                }
                Button("Export as JSON") {
                    showingExport = true
                }
                Button("Share Dashboard") {
                    dashboardManager.shareDashboard()
                }
            } label: {
                Image(systemName: "square.and.arrow.up")
                    .foregroundColor(.blue)
            }
        }
    }
}

// MARK: - Dashboard Widget View

struct DashboardWidgetView: View {
    let widget: DashboardWidget
    let isEditing: Bool
    let onRemove: () -> Void
    let onTap: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Widget header
            HStack {
                Text(widget.title)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Spacer()
                
                if isEditing {
                    Button(action: onRemove) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.red)
                    }
                }
            }
            
            // Widget content
            widgetContent
            
            Spacer()
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
        .onTapGesture {
            onTap()
        }
    }
    
    @ViewBuilder
    private var widgetContent: some View {
        switch widget.type {
        case .healthOverview:
            HealthOverviewWidget(data: widget.data)
        case .activityTrends:
            ActivityTrendsWidget(data: widget.data)
        case .sleepAnalysis:
            SleepAnalysisWidget(data: widget.data)
        case .predictiveInsights:
            PredictiveInsightsWidget(data: widget.data)
        case .custom:
            CustomWidget(data: widget.data)
        }
    }
}

// MARK: - Widget Content Views

struct HealthOverviewWidget: View {
    let data: WidgetData
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(data.subtitle)
                .font(.caption)
                .foregroundColor(.secondary)
            
            HStack {
                VStack(alignment: .leading) {
                    Text("\(Int(data.primaryValue))")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(data.color)
                    
                    Text("Overall Score")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    Text("\(Int(data.secondaryValue))%")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(data.secondaryValue > 0 ? .green : .red)
                    
                    Text("Trend")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            if !data.chartData.isEmpty {
                Chart(data.chartData) { point in
                    LineMark(
                        x: .value("Date", point.date),
                        y: .value("Score", point.value)
                    )
                    .foregroundStyle(data.color)
                }
                .frame(height: 60)
            }
        }
    }
}

struct ActivityTrendsWidget: View {
    let data: WidgetData
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(data.subtitle)
                .font(.caption)
                .foregroundColor(.secondary)
            
            HStack {
                VStack(alignment: .leading) {
                    Text("\(Int(data.primaryValue))")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(data.color)
                    
                    Text("Avg Steps")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    Text("\(Int(data.secondaryValue))%")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(data.secondaryValue > 0 ? .green : .red)
                    
                    Text("Change")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            if !data.chartData.isEmpty {
                Chart(data.chartData) { point in
                    BarMark(
                        x: .value("Date", point.date),
                        y: .value("Steps", point.value)
                    )
                    .foregroundStyle(data.color)
                }
                .frame(height: 60)
            }
        }
    }
}

struct SleepAnalysisWidget: View {
    let data: WidgetData
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(data.subtitle)
                .font(.caption)
                .foregroundColor(.secondary)
            
            HStack {
                VStack(alignment: .leading) {
                    Text(String(format: "%.1f", data.primaryValue))
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(data.color)
                    
                    Text("Hours")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    Text("\(Int(data.secondaryValue))%")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(data.secondaryValue > 80 ? .green : .orange)
                    
                    Text("Quality")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            if !data.chartData.isEmpty {
                Chart(data.chartData) { point in
                    AreaMark(
                        x: .value("Date", point.date),
                        y: .value("Hours", point.value)
                    )
                    .foregroundStyle(data.color.opacity(0.3))
                    
                    LineMark(
                        x: .value("Date", point.date),
                        y: .value("Hours", point.value)
                    )
                    .foregroundStyle(data.color)
                }
                .frame(height: 60)
            }
        }
    }
}

struct PredictiveInsightsWidget: View {
    let data: WidgetData
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(data.subtitle)
                .font(.caption)
                .foregroundColor(.secondary)
            
            HStack {
                VStack(alignment: .leading) {
                    Text("\(Int(data.primaryValue))%")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(data.color)
                    
                    Text("Confidence")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    Text("\(Int(data.secondaryValue))%")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(data.secondaryValue > 0 ? .green : .red)
                    
                    Text("Trend")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            if !data.chartData.isEmpty {
                Chart(data.chartData) { point in
                    LineMark(
                        x: .value("Date", point.date),
                        y: .value("Prediction", point.value)
                    )
                    .foregroundStyle(data.color)
                    .lineStyle(StrokeStyle(lineWidth: 2, dash: [5, 5]))
                }
                .frame(height: 60)
            }
        }
    }
}

struct CustomWidget: View {
    let data: WidgetData
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Custom Widget")
                .font(.headline)
                .foregroundColor(.primary)
            
            Text("Configure your custom widget here")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Spacer()
        }
    }
}

// MARK: - Filter Chip

struct FilterChip: View {
    let filter: AnalyticsFilter
    let onRemove: () -> Void
    
    var body: some View {
        HStack(spacing: 4) {
            Text(filter.name)
                .font(.caption)
                .foregroundColor(.primary)
            
            Button(action: onRemove) {
                Image(systemName: "xmark.circle.fill")
                    .font(.caption)
                    .foregroundColor(.red)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color(.systemGray5))
        .cornerRadius(12)
    }
}

// MARK: - Add Widget View

struct AddWidgetView: View {
    @ObservedObject var dashboardManager: AdvancedAnalyticsDashboardManager
    @Environment(\.dismiss) private var dismiss
    @State private var selectedType: WidgetType = .healthOverview
    @State private var widgetTitle = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section("Widget Type") {
                    Picker("Type", selection: $selectedType) {
                        ForEach(WidgetType.allCases, id: \.self) { type in
                            Text(type.displayName).tag(type)
                        }
                    }
                    .pickerStyle(WheelPickerStyle())
                }
                
                Section("Widget Title") {
                    TextField("Enter widget title", text: $widgetTitle)
                }
            }
            .navigationTitle("Add Widget")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Add") {
                        let title = widgetTitle.isEmpty ? selectedType.displayName : widgetTitle
                        dashboardManager.addWidget(type: selectedType, title: title)
                        dismiss()
                    }
                    .disabled(widgetTitle.isEmpty && selectedType == .custom)
                }
            }
        }
    }
}

// MARK: - Filter View

struct FilterView: View {
    @ObservedObject var dashboardManager: AdvancedAnalyticsDashboardManager
    @Environment(\.dismiss) private var dismiss
    @State private var selectedMetric: HealthMetric = .heartRate
    @State private var dateRange: ClosedRange<Date> = Date().addingTimeInterval(-86400)...Date()
    @State private var valueRange: ClosedRange<Double> = 0...200
    
    var body: some View {
        NavigationView {
            Form {
                Section("Date Range") {
                    DatePicker("Start Date", selection: Binding(
                        get: { dateRange.lowerBound },
                        set: { dateRange = $0...dateRange.upperBound }
                    ), displayedComponents: .date)
                    
                    DatePicker("End Date", selection: Binding(
                        get: { dateRange.upperBound },
                        set: { dateRange = dateRange.lowerBound...$0 }
                    ), displayedComponents: .date)
                }
                
                Section("Health Metric") {
                    Picker("Metric", selection: $selectedMetric) {
                        ForEach(HealthMetric.allCases, id: \.self) { metric in
                            Text(metric.rawValue.capitalized).tag(metric)
                        }
                    }
                }
                
                Section("Value Range") {
                    HStack {
                        Text("Min: \(Int(valueRange.lowerBound))")
                        Slider(value: Binding(
                            get: { valueRange.lowerBound },
                            set: { valueRange = $0...valueRange.upperBound }
                        ), in: 0...200)
                    }
                    
                    HStack {
                        Text("Max: \(Int(valueRange.upperBound))")
                        Slider(value: Binding(
                            get: { valueRange.upperBound },
                            set: { valueRange = valueRange.lowerBound...$0 }
                        ), in: 0...200)
                    }
                }
            }
            .navigationTitle("Filters")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Apply") {
                        applyFilters()
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func applyFilters() {
        // Clear existing filters
        dashboardManager.activeFilters.removeAll()
        
        // Add date range filter
        let dateFilter = DateRangeFilter(
            name: "Date Range",
            dateRange: dateRange
        )
        dashboardManager.activeFilters.append(dateFilter)
        
        // Add metric filter
        let metricFilter = HealthMetricFilter(
            name: "Health Metric",
            metric: selectedMetric
        )
        dashboardManager.activeFilters.append(metricFilter)
        
        // Add value range filter
        let valueFilter = ValueRangeFilter(
            name: "Value Range",
            range: valueRange
        )
        dashboardManager.activeFilters.append(valueFilter)
        
        dashboardManager.refreshDashboard()
    }
}

// MARK: - Comparison View

struct ComparisonView: View {
    @ObservedObject var dashboardManager: AdvancedAnalyticsDashboardManager
    @Environment(\.dismiss) private var dismiss
    @State private var selectedMode: ComparisonMode = .periodOverPeriod
    
    var body: some View {
        NavigationView {
            Form {
                Section("Comparison Mode") {
                    Picker("Mode", selection: $selectedMode) {
                        ForEach(ComparisonMode.allCases, id: \.self) { mode in
                            Text(mode.displayName).tag(mode)
                        }
                    }
                    .pickerStyle(WheelPickerStyle())
                }
                
                Section("Description") {
                    Text(selectedMode.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle("Comparison")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Apply") {
                        dashboardManager.comparisonMode = selectedMode
                        dashboardManager.refreshDashboard()
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Export View

struct ExportView: View {
    @ObservedObject var dashboardManager: AdvancedAnalyticsDashboardManager
    @Environment(\.dismiss) private var dismiss
    @State private var exportFormat: ExportFormat = .csv
    @State private var isExporting = false
    
    enum ExportFormat: String, CaseIterable {
        case csv = "CSV"
        case json = "JSON"
        case image = "Image"
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section("Export Format") {
                    Picker("Format", selection: $exportFormat) {
                        ForEach(ExportFormat.allCases, id: \.self) { format in
                            Text(format.rawValue).tag(format)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }
                
                Section("Export Options") {
                    Button(action: exportData) {
                        HStack {
                            if isExporting {
                                ProgressView()
                                    .scaleEffect(0.8)
                            } else {
                                Image(systemName: "square.and.arrow.up")
                            }
                            Text("Export Dashboard")
                        }
                    }
                    .disabled(isExporting)
                }
            }
            .navigationTitle("Export")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func exportData() {
        isExporting = true
        
        Task {
            switch exportFormat {
            case .csv:
                let csvData = await dashboardManager.exportDashboardAsCSV()
                // Handle CSV export
                break
            case .json:
                let jsonData = await dashboardManager.exportDashboardAsJSON()
                // Handle JSON export
                break
            case .image:
                let image = await dashboardManager.exportDashboardAsImage()
                // Handle image export
                break
            }
            
            await MainActor.run {
                isExporting = false
            }
        }
    }
}

// MARK: - Extensions

extension ComparisonMode {
    var displayName: String {
        switch self {
        case .none: return "None"
        case .periodOverPeriod: return "Period over Period"
        case .goalVsActual: return "Goal vs Actual"
        case .peerGroup: return "Peer Group"
        case .historical: return "Historical"
        }
    }
    
    var description: String {
        switch self {
        case .none:
            return "No comparison mode selected"
        case .periodOverPeriod:
            return "Compare current period with previous period"
        case .goalVsActual:
            return "Compare actual performance with set goals"
        case .peerGroup:
            return "Compare with similar users in your age group"
        case .historical:
            return "Compare with historical data trends"
        }
    }
}

// MARK: - Preview

struct AdvancedAnalyticsDashboardView_Previews: PreviewProvider {
    static var previews: some View {
        AdvancedAnalyticsDashboardView(
            healthDataManager: HealthDataManager(),
            analyticsEngine: AnalyticsEngine(),
            mlModelManager: MLModelManager()
        )
    }
} 