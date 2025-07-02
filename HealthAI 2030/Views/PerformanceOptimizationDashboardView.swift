import SwiftUI
import Combine
import Charts

/// Comprehensive performance monitoring and optimization dashboard
struct PerformanceOptimizationDashboardView: View {
    @StateObject private var neuralEngineOptimizer = NeuralEngineOptimizer.shared
    @StateObject private var metalOptimizer = MetalGraphicsOptimizer.shared
    @StateObject private var memoryManager = AdvancedMemoryManager.shared
    @StateObject private var backgroundScheduler = BackgroundTaskScheduler.shared
    
    @State private var selectedPerformanceMode: PerformanceMode = .balanced
    @State private var showingOptimizationSettings = false
    @State private var showingPerformanceAlerts = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack(spacing: 16) {
                    // Performance Mode Selector
                    performanceModeCard
                    
                    // System Metrics
                    systemMetricsSection
                    
                    // ML Performance
                    mlPerformanceSection
                    
                    // Memory & Storage
                    memorySection
                    
                    // Battery & Power
                    batterySection
                    
                    // Background Tasks
                    backgroundTasksSection
                    
                    // Optimization Controls
                    optimizationControlsSection
                }
                .padding()
            }
            .navigationTitle("Performance")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Settings") {
                        showingOptimizationSettings = true
                    }
                }
            }
            .sheet(isPresented: $showingOptimizationSettings) {
                PerformanceSettingsView()
            }
            .sheet(isPresented: $showingPerformanceAlerts) {
                PerformanceAlertsView()
            }
        }
    }
    
    // MARK: - Performance Mode Card
    private var performanceModeCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "speedometer")
                    .font(.title2)
                    .foregroundColor(.blue)
                
                Text("Performance Mode")
                    .font(.headline)
                
                Spacer()
                
                Button("Change") {
                    showingOptimizationSettings = true
                }
                .font(.caption)
                .foregroundColor(.blue)
            }
            
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(selectedPerformanceMode.displayName)
                        .font(.title3)
                        .fontWeight(.semibold)
                    
                    Text(selectedPerformanceMode.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: selectedPerformanceMode.iconName)
                    .font(.title)
                    .foregroundColor(selectedPerformanceMode.color)
            }
            
            // Performance indicators
            HStack(spacing: 16) {
                PerformanceIndicator(
                    title: "CPU",
                    value: neuralEngineOptimizer.cpuUsage,
                    unit: "%",
                    color: .orange
                )
                
                PerformanceIndicator(
                    title: "Memory",
                    value: memoryManager.memoryUsage,
                    unit: "%",
                    color: .purple
                )
                
                PerformanceIndicator(
                    title: "Battery",
                    value: neuralEngineOptimizer.batteryLevel,
                    unit: "%",
                    color: .green
                )
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    // MARK: - System Metrics Section
    private var systemMetricsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "System Metrics", icon: "chart.bar.fill")
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                MetricCard(
                    title: "CPU Usage",
                    value: String(format: "%.1f%%", neuralEngineOptimizer.cpuUsage),
                    subtitle: "Core utilization",
                    icon: "cpu",
                    color: .orange
                )
                
                MetricCard(
                    title: "GPU Usage",
                    value: String(format: "%.1f%%", metalOptimizer.gpuUsage),
                    subtitle: "Graphics processing",
                    icon: "display",
                    color: .blue
                )
                
                MetricCard(
                    title: "Memory Usage",
                    value: String(format: "%.1f GB", memoryManager.usedMemory),
                    subtitle: "Active memory",
                    icon: "memorychip",
                    color: .purple
                )
                
                MetricCard(
                    title: "Storage",
                    value: String(format: "%.1f GB", memoryManager.availableStorage),
                    subtitle: "Available space",
                    icon: "internaldrive",
                    color: .gray
                )
            }
        }
    }
    
    // MARK: - ML Performance Section
    private var mlPerformanceSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "ML Performance", icon: "brain.head.profile")
            
            VStack(spacing: 12) {
                // Neural Engine Status
                HStack {
                    Image(systemName: "cpu")
                        .foregroundColor(.blue)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Neural Engine")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        Text(neuralEngineOptimizer.neuralEngineStatus.displayName)
                            .font(.caption)
                            .foregroundColor(neuralEngineOptimizer.neuralEngineStatus.color)
                    }
                    
                    Spacer()
                    
                    Text("\(Int(neuralEngineOptimizer.neuralEngineUtilization))%")
                        .font(.headline)
                        .fontWeight(.semibold)
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(8)
                
                // ML Task Performance Chart
                VStack(alignment: .leading, spacing: 8) {
                    Text("ML Task Performance")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Chart(neuralEngineOptimizer.mlTaskHistory) { task in
                        LineMark(
                            x: .value("Time", task.timestamp),
                            y: .value("Duration", task.duration)
                        )
                        .foregroundStyle(.blue)
                        
                        AreaMark(
                            x: .value("Time", task.timestamp),
                            y: .value("Duration", task.duration)
                        )
                        .foregroundStyle(.blue.opacity(0.1))
                    }
                    .frame(height: 120)
                    .chartYAxis {
                        AxisMarks(position: .leading)
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(8)
            }
        }
    }
    
    // MARK: - Memory Section
    private var memorySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Memory & Storage", icon: "memorychip")
            
            VStack(spacing: 12) {
                // Memory Usage Chart
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Memory Usage")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        Spacer()
                        
                        Text("\(Int(memoryManager.memoryUsage))%")
                            .font(.headline)
                            .fontWeight(.semibold)
                    }
                    
                    ProgressView(value: memoryManager.memoryUsage / 100.0)
                        .progressViewStyle(LinearProgressViewStyle(tint: memoryManager.memoryUsage > 80 ? .red : .blue))
                    
                    HStack {
                        Text("Used: \(String(format: "%.1f GB", memoryManager.usedMemory))")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        Text("Available: \(String(format: "%.1f GB", memoryManager.availableMemory))")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(8)
                
                // Memory Optimization Status
                HStack {
                    Image(systemName: memoryManager.isOptimizationActive ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                        .foregroundColor(memoryManager.isOptimizationActive ? .green : .orange)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Memory Optimization")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        Text(memoryManager.isOptimizationActive ? "Active" : "Recommended")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Button(memoryManager.isOptimizationActive ? "Disable" : "Enable") {
                        if memoryManager.isOptimizationActive {
                            memoryManager.disableOptimization()
                        } else {
                            memoryManager.enableOptimization()
                        }
                    }
                    .font(.caption)
                    .foregroundColor(.blue)
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(8)
            }
        }
    }
    
    // MARK: - Battery Section
    private var batterySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Battery & Power", icon: "battery.100")
            
            VStack(spacing: 12) {
                // Battery Status
                HStack {
                    Image(systemName: batteryIconName)
                        .font(.title2)
                        .foregroundColor(batteryColor)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Battery Level")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        Text("\(Int(neuralEngineOptimizer.batteryLevel))%")
                            .font(.headline)
                            .fontWeight(.semibold)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("Power Mode")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text(neuralEngineOptimizer.powerMode.displayName)
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(8)
                
                // Power Consumption
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Power Consumption")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        Text("\(String(format: "%.1f", neuralEngineOptimizer.powerConsumption))W")
                            .font(.title3)
                            .fontWeight(.semibold)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("Temperature")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text("\(String(format: "%.1f°C", neuralEngineOptimizer.deviceTemperature))")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(neuralEngineOptimizer.deviceTemperature > 40 ? .red : .primary)
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(8)
            }
        }
    }
    
    // MARK: - Background Tasks Section
    private var backgroundTasksSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Background Tasks", icon: "clock.arrow.circlepath")
            
            VStack(spacing: 8) {
                ForEach(backgroundScheduler.activeTasks) { task in
                    HStack {
                        Image(systemName: task.iconName)
                            .foregroundColor(.blue)
                            .frame(width: 20)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(task.name)
                                .font(.subheadline)
                                .fontWeight(.medium)
                            
                            Text(task.status.displayName)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        Text(task.nextRunTime, style: .relative)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(8)
        }
    }
    
    // MARK: - Optimization Controls Section
    private var optimizationControlsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Optimization Controls", icon: "slider.horizontal.3")
            
            VStack(spacing: 12) {
                // Quick Optimization Actions
                HStack(spacing: 12) {
                    Button("Optimize Now") {
                        performQuickOptimization()
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
                    
                    Button("Clear Cache") {
                        memoryManager.clearCache()
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                    
                    Button("Restart ML") {
                        neuralEngineOptimizer.restartMLPipeline()
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                }
                
                // Performance Alerts
                if neuralEngineOptimizer.hasPerformanceAlerts {
                    Button("View Alerts (\(neuralEngineOptimizer.performanceAlerts.count))") {
                        showingPerformanceAlerts = true
                    }
                    .buttonStyle(.bordered)
                    .foregroundColor(.orange)
                    .controlSize(.small)
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(8)
        }
    }
    
    // MARK: - Helper Methods
    private var batteryIconName: String {
        let level = neuralEngineOptimizer.batteryLevel
        if level > 80 { return "battery.100" }
        else if level > 60 { return "battery.75" }
        else if level > 40 { return "battery.50" }
        else if level > 20 { return "battery.25" }
        else { return "battery.0" }
    }
    
    private var batteryColor: Color {
        let level = neuralEngineOptimizer.batteryLevel
        if level > 50 { return .green }
        else if level > 20 { return .orange }
        else { return .red }
    }
    
    private func performQuickOptimization() {
        Task {
            await neuralEngineOptimizer.performQuickOptimization()
            await memoryManager.performMemoryOptimization()
            await metalOptimizer.optimizeGraphicsPipeline()
        }
    }
}

// MARK: - Supporting Views
struct SectionHeader: View {
    let title: String
    let icon: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.blue)
            
            Text(title)
                .font(.headline)
                .fontWeight(.semibold)
        }
    }
}

struct PerformanceIndicator: View {
    let title: String
    let value: Double
    let unit: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text("\(Int(value))\(unit)")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(color)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
}

struct MetricCard: View {
    let title: String
    let value: String
    let subtitle: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                
                Spacer()
                
                Text(value)
                    .font(.headline)
                    .fontWeight(.semibold)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
}

// MARK: - Performance Mode
enum PerformanceMode: String, CaseIterable {
    case batterySaver = "battery_saver"
    case balanced = "balanced"
    case highPerformance = "high_performance"
    case maxPerformance = "max_performance"
    
    var displayName: String {
        switch self {
        case .batterySaver: return "Battery Saver"
        case .balanced: return "Balanced"
        case .highPerformance: return "High Performance"
        case .maxPerformance: return "Max Performance"
        }
    }
    
    var description: String {
        switch self {
        case .batterySaver: return "Optimized for battery life"
        case .balanced: return "Balanced performance and battery"
        case .highPerformance: return "Enhanced performance mode"
        case .maxPerformance: return "Maximum performance mode"
        }
    }
    
    var iconName: String {
        switch self {
        case .batterySaver: return "battery.25"
        case .balanced: return "speedometer"
        case .highPerformance: return "bolt.fill"
        case .maxPerformance: return "flame.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .batterySaver: return .green
        case .balanced: return .blue
        case .highPerformance: return .orange
        case .maxPerformance: return .red
        }
    }
}

// MARK: - Preview
struct PerformanceOptimizationDashboardView_Previews: PreviewProvider {
    static var previews: some View {
        PerformanceOptimizationDashboardView()
    }
} 