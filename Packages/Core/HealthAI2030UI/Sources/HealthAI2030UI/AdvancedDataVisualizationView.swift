import SwiftUI
import Charts
import Combine
@testable import HealthAI2030Advanced

/// Advanced Data Visualization View
/// Demonstrates integration of the Advanced Data Visualization Engine with SwiftUI
@available(iOS 18.0, macOS 15.0, *)
struct AdvancedDataVisualizationView: View {
    @StateObject private var visualizationEngine = AdvancedDataVisualizationEngine.shared
    @State private var visualizations: [HealthVisualization] = []
    @State private var selectedVisualization: HealthVisualization?
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showingExportSheet = false
    @State private var exportFormat: ExportFormat = .png
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Performance metrics
                    PerformanceMetricsView(performance: visualizationEngine.renderingPerformance)
                    
                    // Visualization controls
                    VisualizationControlsView(
                        isLoading: isLoading,
                        onRefresh: loadVisualizations,
                        onOptimize: optimizePerformance
                    )
                    
                    // Visualizations grid
                    if visualizations.isEmpty && !isLoading {
                        EmptyStateView()
                    } else {
                        VisualizationsGridView(
                            visualizations: visualizations,
                            selectedVisualization: $selectedVisualization
                        )
                    }
                }
                .padding()
            }
            .navigationTitle("Advanced Visualizations")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Export") {
                        showingExportSheet = true
                    }
                    .disabled(selectedVisualization == nil)
                }
            }
            .task {
                await loadVisualizations()
            }
            .refreshable {
                await loadVisualizations()
            }
            .alert("Error", isPresented: .constant(errorMessage != nil)) {
                Button("OK") {
                    errorMessage = nil
                }
            } message: {
                Text(errorMessage ?? "")
            }
            .sheet(isPresented: $showingExportSheet) {
                ExportSheetView(
                    visualization: selectedVisualization,
                    format: $exportFormat,
                    onExport: exportVisualization
                )
            }
        }
    }
    
    private func loadVisualizations() async {
        isLoading = true
        errorMessage = nil
        
        do {
            // Create sample health data for demonstration
            let sampleData = createSampleHealthData()
            visualizations = try await visualizationEngine.createVisualizations(for: sampleData)
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    private func optimizePerformance() async {
        do {
            try await visualizationEngine.optimizePerformance()
        } catch {
            errorMessage = "Failed to optimize performance: \(error.localizedDescription)"
        }
    }
    
    private func exportVisualization() async {
        guard let visualization = selectedVisualization else { return }
        
        do {
            let imageData = try await visualizationEngine.exportVisualization(visualization, format: exportFormat)
            // Handle successful export (save to files, share, etc.)
            print("Exported visualization: \(visualization.title)")
        } catch {
            errorMessage = "Failed to export visualization: \(error.localizedDescription)"
        }
    }
    
    private func createSampleHealthData() -> HealthVisualizationData {
        let now = Date()
        let points = (0..<24).map { hour in
            HealthDataPoint(
                timestamp: Calendar.current.date(byAdding: .hour, value: -hour, to: now) ?? now,
                value: Double.random(in: 60...100),
                label: "Heart Rate",
                category: "Cardiac",
                color: .red,
                xValue: nil,
                size: nil,
                metadata: ["zone": heartRateZone(for: Double.random(in: 60...100))]
            )
        }
        
        return HealthVisualizationData(
            points: points,
            metric: "Heart Rate",
            source: "Apple Health",
            metadata: ["type": "time_series", "unit": "BPM"]
        )
    }
    
    private func heartRateZone(for heartRate: Double) -> String {
        switch heartRate {
        case 0..<60: return "Resting"
        case 60..<100: return "Normal"
        case 100..<140: return "Elevated"
        default: return "Maximum"
        }
    }
}

// MARK: - Performance Metrics View

struct PerformanceMetricsView: View {
    let performance: RenderingPerformance
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Performance Metrics")
                .font(.headline)
                .fontWeight(.semibold)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                MetricCard(
                    title: "Avg Render Time",
                    value: String(format: "%.2fs", performance.averageRenderTime),
                    icon: "clock"
                )
                
                MetricCard(
                    title: "Total Renders",
                    value: "\(performance.totalRenders)",
                    icon: "chart.bar"
                )
                
                MetricCard(
                    title: "Memory Usage",
                    value: String(format: "%.1fMB", performance.memoryUsage),
                    icon: "memorychip"
                )
                
                MetricCard(
                    title: "GPU Utilization",
                    value: String(format: "%.1f%%", performance.gpuUtilization),
                    icon: "cpu"
                )
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct MetricCard: View {
    let title: String
    let value: String
    let icon: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(.accentColor)
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(8)
    }
}

// MARK: - Visualization Controls View

struct VisualizationControlsView: View {
    let isLoading: Bool
    let onRefresh: () async -> Void
    let onOptimize: () async -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            Button(action: {
                Task { await onRefresh() }
            }) {
                HStack {
                    if isLoading {
                        ProgressView()
                            .scaleEffect(0.8)
                    } else {
                        Image(systemName: "arrow.clockwise")
                    }
                    Text(isLoading ? "Loading..." : "Refresh")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.accentColor)
                .foregroundColor(.white)
                .cornerRadius(8)
            }
            .disabled(isLoading)
            
            Button(action: {
                Task { await onOptimize() }
            }) {
                HStack {
                    Image(systemName: "speedometer")
                    Text("Optimize")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color(.systemGray5))
                .foregroundColor(.primary)
                .cornerRadius(8)
            }
        }
    }
}

// MARK: - Visualizations Grid View

struct VisualizationsGridView: View {
    let visualizations: [HealthVisualization]
    @Binding var selectedVisualization: HealthVisualization?
    
    var body: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: 16) {
            ForEach(visualizations) { visualization in
                VisualizationCardView(
                    visualization: visualization,
                    isSelected: selectedVisualization?.id == visualization.id
                )
                .onTapGesture {
                    selectedVisualization = visualization
                }
            }
        }
    }
}

struct VisualizationCardView: View {
    let visualization: HealthVisualization
    let isSelected: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Chart preview
            ChartPreviewView(visualization: visualization)
                .frame(height: 120)
            
            // Visualization info
            VStack(alignment: .leading, spacing: 4) {
                Text(visualization.title)
                    .font(.headline)
                    .lineLimit(1)
                
                Text(visualization.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                
                HStack {
                    Label("\(visualization.metadata.dataPoints) points", systemImage: "chart.point")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text(visualization.metadata.dataSource)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isSelected ? Color.accentColor : Color.clear, lineWidth: 2)
        )
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
}

struct ChartPreviewView: View {
    let visualization: HealthVisualization
    
    var body: some View {
        Group {
            switch visualization.type {
            case .chart(let chartType):
                ChartTypePreviewView(chartType: chartType, data: visualization.data)
            case .realTimeStream:
                RealTimePreviewView(data: visualization.data)
            default:
                Text("Preview not available")
                    .foregroundColor(.secondary)
            }
        }
    }
}

struct ChartTypePreviewView: View {
    let chartType: ChartType
    let data: [String: Any]
    
    var body: some View {
        Group {
            switch chartType {
            case .lineChart:
                LineChartPreview(data: data)
            case .barChart:
                BarChartPreview(data: data)
            case .pieChart:
                PieChartPreview(data: data)
            case .scatterPlot:
                ScatterPlotPreview(data: data)
            case .heatmap:
                HeatmapPreview(data: data)
            case .areaChart:
                AreaChartPreview(data: data)
            case .histogram:
                HistogramPreview(data: data)
            case .boxPlot:
                BoxPlotPreview(data: data)
            }
        }
    }
}

// MARK: - Chart Preview Views

struct LineChartPreview: View {
    let data: [String: Any]
    
    var body: some View {
        if let xAxis = data["xAxis"] as? [Double],
           let yAxis = data["yAxis"] as? [Double] {
            Chart {
                ForEach(Array(zip(xAxis, yAxis).enumerated()), id: \.offset) { index, point in
                    LineMark(
                        x: .value("Time", point.0),
                        y: .value("Value", point.1)
                    )
                    .foregroundStyle(.blue)
                }
            }
            .chartYAxis { AxisMarks() }
            .chartXAxis { AxisMarks() }
        } else {
            Text("No data")
                .foregroundColor(.secondary)
        }
    }
}

struct BarChartPreview: View {
    let data: [String: Any]
    
    var body: some View {
        if let categories = data["categories"] as? [String],
           let values = data["values"] as? [Double] {
            Chart {
                ForEach(Array(zip(categories, values).enumerated()), id: \.offset) { index, point in
                    BarMark(
                        x: .value("Category", point.0),
                        y: .value("Value", point.1)
                    )
                    .foregroundStyle(.green)
                }
            }
            .chartYAxis { AxisMarks() }
            .chartXAxis { AxisMarks() }
        } else {
            Text("No data")
                .foregroundColor(.secondary)
        }
    }
}

struct PieChartPreview: View {
    let data: [String: Any]
    
    var body: some View {
        if let labels = data["labels"] as? [String],
           let values = data["values"] as? [Double] {
            Chart {
                ForEach(Array(zip(labels, values).enumerated()), id: \.offset) { index, point in
                    SectorMark(
                        angle: .value("Value", point.1),
                        innerRadius: .ratio(0.5),
                        angularInset: 2
                    )
                    .foregroundStyle(by: .value("Category", point.0))
                }
            }
        } else {
            Text("No data")
                .foregroundColor(.secondary)
        }
    }
}

struct ScatterPlotPreview: View {
    let data: [String: Any]
    
    var body: some View {
        if let xValues = data["xValues"] as? [Double],
           let yValues = data["yValues"] as? [Double] {
            Chart {
                ForEach(Array(zip(xValues, yValues).enumerated()), id: \.offset) { index, point in
                    PointMark(
                        x: .value("X", point.0),
                        y: .value("Y", point.1)
                    )
                    .foregroundStyle(.red)
                }
            }
            .chartYAxis { AxisMarks() }
            .chartXAxis { AxisMarks() }
        } else {
            Text("No data")
                .foregroundColor(.secondary)
        }
    }
}

struct HeatmapPreview: View {
    let data: [String: Any]
    
    var body: some View {
        if let grid = data["grid"] as? [[Double]] {
            VStack(spacing: 1) {
                ForEach(grid.indices, id: \.self) { row in
                    HStack(spacing: 1) {
                        ForEach(grid[row].indices, id: \.self) { col in
                            Rectangle()
                                .fill(colorForValue(grid[row][col]))
                                .frame(width: 8, height: 8)
                        }
                    }
                }
            }
        } else {
            Text("No data")
                .foregroundColor(.secondary)
        }
    }
    
    private func colorForValue(_ value: Double) -> Color {
        let normalized = value / 100.0
        return Color.blue.opacity(normalized)
    }
}

struct AreaChartPreview: View {
    let data: [String: Any]
    
    var body: some View {
        if let xAxis = data["xAxis"] as? [Double],
           let yAxis = data["yAxis"] as? [Double] {
            Chart {
                ForEach(Array(zip(xAxis, yAxis).enumerated()), id: \.offset) { index, point in
                    AreaMark(
                        x: .value("Time", point.0),
                        y: .value("Value", point.1)
                    )
                    .foregroundStyle(.blue.opacity(0.3))
                    
                    LineMark(
                        x: .value("Time", point.0),
                        y: .value("Value", point.1)
                    )
                    .foregroundStyle(.blue)
                }
            }
            .chartYAxis { AxisMarks() }
            .chartXAxis { AxisMarks() }
        } else {
            Text("No data")
                .foregroundColor(.secondary)
        }
    }
}

struct HistogramPreview: View {
    let data: [String: Any]
    
    var body: some View {
        if let bins = data["bins"] as? [Int] {
            Chart {
                ForEach(bins.indices, id: \.self) { index in
                    BarMark(
                        x: .value("Bin", index),
                        y: .value("Count", bins[index])
                    )
                    .foregroundStyle(.purple)
                }
            }
            .chartYAxis { AxisMarks() }
            .chartXAxis { AxisMarks() }
        } else {
            Text("No data")
                .foregroundColor(.secondary)
        }
    }
}

struct BoxPlotPreview: View {
    let data: [String: Any]
    
    var body: some View {
        if let min = data["min"] as? Double,
           let q1 = data["q1"] as? Double,
           let median = data["median"] as? Double,
           let q3 = data["q3"] as? Double,
           let max = data["max"] as? Double {
            VStack(spacing: 4) {
                Rectangle()
                    .fill(Color.orange)
                    .frame(height: 2)
                    .frame(maxWidth: .infinity)
                
                Rectangle()
                    .fill(Color.orange)
                    .frame(height: 20)
                    .frame(maxWidth: .infinity)
                
                Rectangle()
                    .fill(Color.orange)
                    .frame(height: 2)
                    .frame(maxWidth: .infinity)
            }
            .overlay(
                Rectangle()
                    .stroke(Color.orange, lineWidth: 1)
            )
        } else {
            Text("No data")
                .foregroundColor(.secondary)
        }
    }
}

struct RealTimePreviewView: View {
    let data: [String: Any]
    
    var body: some View {
        VStack {
            Image(systemName: "waveform")
                .font(.title)
                .foregroundColor(.green)
            
            Text("Live Data")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - Empty State View

struct EmptyStateView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "chart.bar.doc.horizontal")
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            
            Text("No Visualizations")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Create your first health data visualization to get started.")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Export Sheet View

struct ExportSheetView: View {
    let visualization: HealthVisualization?
    @Binding var format: ExportFormat
    let onExport: () async -> Void
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                if let visualization = visualization {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Export Visualization")
                            .font(.headline)
                        
                        Text(visualization.title)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Text("Data points: \(visualization.metadata.dataPoints)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                }
                
                VStack(alignment: .leading, spacing: 12) {
                    Text("Export Format")
                        .font(.headline)
                    
                    Picker("Format", selection: $format) {
                        ForEach(ExportFormat.allCases, id: \.self) { format in
                            Text(format.rawValue).tag(format)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }
                
                Spacer()
                
                Button("Export") {
                    Task {
                        await onExport()
                        dismiss()
                    }
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.accentColor)
                .foregroundColor(.white)
                .cornerRadius(8)
            }
            .padding()
            .navigationTitle("Export")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Preview

@available(iOS 18.0, macOS 15.0, *)
struct AdvancedDataVisualizationView_Previews: PreviewProvider {
    static var previews: some View {
        AdvancedDataVisualizationView()
    }
} 