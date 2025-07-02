import SwiftUI

/// Performance optimization settings and configuration
struct PerformanceSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var neuralEngineOptimizer = NeuralEngineOptimizer.shared
    @StateObject private var metalOptimizer = MetalGraphicsOptimizer.shared
    @StateObject private var memoryManager = AdvancedMemoryManager.shared
    
    @State private var selectedPerformanceMode: PerformanceMode = .balanced
    @State private var autoOptimizationEnabled = true
    @State private var aggressiveMemoryCompression = false
    @State private var neuralEnginePriority = NeuralEnginePriority.balanced
    @State private var graphicsQuality = GraphicsQuality.auto
    @State private var backgroundTaskLimit = 5
    
    var body: some View {
        NavigationStack {
            Form {
                // Performance Mode Section
                Section("Performance Mode") {
                    Picker("Mode", selection: $selectedPerformanceMode) {
                        ForEach(PerformanceMode.allCases, id: \.self) { mode in
                            HStack {
                                Image(systemName: mode.iconName)
                                    .foregroundColor(mode.color)
                                Text(mode.displayName)
                            }
                            .tag(mode)
                        }
                    }
                    .pickerStyle(.menu)
                    
                    Text(selectedPerformanceMode.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                // Neural Engine Section
                Section("Neural Engine") {
                    Picker("Priority", selection: $neuralEnginePriority) {
                        ForEach(NeuralEnginePriority.allCases, id: \.self) { priority in
                            Text(priority.displayName).tag(priority)
                        }
                    }
                    .pickerStyle(.segmented)
                    
                    Toggle("Auto-optimize models", isOn: $autoOptimizationEnabled)
                    
                    Toggle("Use Neural Engine for all ML tasks", isOn: .constant(true))
                        .disabled(true)
                    
                    HStack {
                        Text("Model cache size")
                        Spacer()
                        Text("\(neuralEngineOptimizer.modelCacheSize) MB")
                            .foregroundColor(.secondary)
                    }
                }
                
                // Graphics Section
                Section("Graphics & Metal") {
                    Picker("Graphics Quality", selection: $graphicsQuality) {
                        ForEach(GraphicsQuality.allCases, id: \.self) { quality in
                            Text(quality.displayName).tag(quality)
                        }
                    }
                    .pickerStyle(.menu)
                    
                    Toggle("Enable Metal optimization", isOn: .constant(true))
                        .disabled(true)
                    
                    Toggle("Use hardware acceleration", isOn: .constant(true))
                        .disabled(true)
                    
                    HStack {
                        Text("GPU memory limit")
                        Spacer()
                        Text("\(metalOptimizer.gpuMemoryLimit) MB")
                            .foregroundColor(.secondary)
                    }
                }
                
                // Memory Section
                Section("Memory Management") {
                    Toggle("Aggressive compression", isOn: $aggressiveMemoryCompression)
                    
                    Toggle("Auto-clear cache", isOn: .constant(true))
                        .disabled(true)
                    
                    HStack {
                        Text("Background task limit")
                        Spacer()
                        Stepper("\(backgroundTaskLimit)", value: $backgroundTaskLimit, in: 1...10)
                    }
                    
                    HStack {
                        Text("Memory threshold")
                        Spacer()
                        Text("\(Int(memoryManager.memoryThreshold * 100))%")
                            .foregroundColor(.secondary)
                    }
                }
                
                // Battery Section
                Section("Battery & Power") {
                    HStack {
                        Text("Power mode")
                        Spacer()
                        Text(neuralEngineOptimizer.powerMode.displayName)
                            .foregroundColor(.secondary)
                    }
                    
                    Toggle("Low power mode optimization", isOn: .constant(true))
                        .disabled(true)
                    
                    HStack {
                        Text("Battery threshold")
                        Spacer()
                        Text("20%")
                            .foregroundColor(.secondary)
                    }
                }
                
                // Advanced Section
                Section("Advanced") {
                    Button("Reset to defaults") {
                        resetToDefaults()
                    }
                    .foregroundColor(.red)
                    
                    Button("Export performance data") {
                        exportPerformanceData()
                    }
                    
                    Button("Clear all caches") {
                        clearAllCaches()
                    }
                    .foregroundColor(.orange)
                }
            }
            .navigationTitle("Performance Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveSettings()
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
        .onAppear {
            loadCurrentSettings()
        }
    }
    
    // MARK: - Helper Methods
    private func loadCurrentSettings() {
        selectedPerformanceMode = UserDefaults.standard.string(forKey: "performance_mode").flatMap { PerformanceMode(rawValue: $0) } ?? .balanced
        autoOptimizationEnabled = UserDefaults.standard.bool(forKey: "auto_optimization_enabled")
        aggressiveMemoryCompression = UserDefaults.standard.bool(forKey: "aggressive_memory_compression")
        neuralEnginePriority = NeuralEnginePriority(rawValue: UserDefaults.standard.string(forKey: "neural_engine_priority") ?? "balanced") ?? .balanced
        graphicsQuality = GraphicsQuality(rawValue: UserDefaults.standard.string(forKey: "graphics_quality") ?? "auto") ?? .auto
        backgroundTaskLimit = UserDefaults.standard.integer(forKey: "background_task_limit")
        if backgroundTaskLimit == 0 { backgroundTaskLimit = 5 }
    }
    
    private func saveSettings() {
        UserDefaults.standard.set(selectedPerformanceMode.rawValue, forKey: "performance_mode")
        UserDefaults.standard.set(autoOptimizationEnabled, forKey: "auto_optimization_enabled")
        UserDefaults.standard.set(aggressiveMemoryCompression, forKey: "aggressive_memory_compression")
        UserDefaults.standard.set(neuralEnginePriority.rawValue, forKey: "neural_engine_priority")
        UserDefaults.standard.set(graphicsQuality.rawValue, forKey: "graphics_quality")
        UserDefaults.standard.set(backgroundTaskLimit, forKey: "background_task_limit")
        
        // Apply settings
        applyPerformanceSettings()
    }
    
    private func applyPerformanceSettings() {
        Task {
            await neuralEngineOptimizer.setPriority(neuralEnginePriority)
            await metalOptimizer.setGraphicsQuality(graphicsQuality)
            await memoryManager.setCompressionMode(aggressiveMemoryCompression ? .aggressive : .normal)
        }
    }
    
    private func resetToDefaults() {
        selectedPerformanceMode = .balanced
        autoOptimizationEnabled = true
        aggressiveMemoryCompression = false
        neuralEnginePriority = .balanced
        graphicsQuality = .auto
        backgroundTaskLimit = 5
    }
    
    private func exportPerformanceData() {
        Task {
            let data = await neuralEngineOptimizer.exportPerformanceData()
            // Handle data export
            print("Performance data exported")
        }
    }
    
    private func clearAllCaches() {
        Task {
            await neuralEngineOptimizer.clearModelCache()
            await metalOptimizer.clearGraphicsCache()
            await memoryManager.clearAllCaches()
        }
    }
}

// MARK: - Supporting Types
enum NeuralEnginePriority: String, CaseIterable {
    case battery = "battery"
    case balanced = "balanced"
    case performance = "performance"
    
    var displayName: String {
        switch self {
        case .battery: return "Battery"
        case .balanced: return "Balanced"
        case .performance: return "Performance"
        }
    }
}

enum GraphicsQuality: String, CaseIterable {
    case low = "low"
    case medium = "medium"
    case high = "high"
    case auto = "auto"
    
    var displayName: String {
        switch self {
        case .low: return "Low"
        case .medium: return "Medium"
        case .high: return "High"
        case .auto: return "Auto"
        }
    }
}

// MARK: - Preview
struct PerformanceSettingsView_Previews: PreviewProvider {
    static var previews: some View {
        PerformanceSettingsView()
    }
} 