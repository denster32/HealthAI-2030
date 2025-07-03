import Foundation
import Metal
import MetalKit
import simd
import Combine

/// Metal Graphics Optimizer
/// Optimizes graphics rendering using Metal for Vision Pro and real-time health data visualization
class MetalGraphicsOptimizer: ObservableObject {
    // MARK: - Published Properties
    @Published var isOptimizing = false
    @Published var optimizationProgress: Double = 0.0
    @Published var currentPerformance: GraphicsPerformance = GraphicsPerformance()
    @Published var optimizationStatus: OptimizationStatus = .idle
    
    // MARK: - Private Properties
    private var device: MTLDevice?
    private var commandQueue: MTLCommandQueue?
    private var library: MTLLibrary?
    
    // Graphics optimization components
    private var renderPipelineOptimizer: RenderPipelineOptimizer?
    private var memoryOptimizer: MemoryOptimizer?
    private var shaderOptimizer: ShaderOptimizer?
    
    // Performance monitoring
    private var performanceMonitor: GraphicsPerformanceMonitor?
    private var performanceHistory: [GraphicsPerformance] = []
    private let maxHistorySize = 100
    
    // Metal configuration
    private var metalConfig: MetalConfig = MetalConfig()
    private var optimizationCache: [String: OptimizedGraphicsResource] = [:]
    
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        setupMetalGraphicsOptimizer()
    }
    
    deinit {
        cleanup()
    }
    
    // MARK: - Public Methods
    
    /// Initialize Metal device and setup optimization
    func initializeMetal() throws {
        guard let device = MTLCreateSystemDefaultDevice() else {
            throw MetalError.deviceNotFound
        }
        
        self.device = device
        self.commandQueue = device.makeCommandQueue()
        
        // Load default Metal library
        self.library = device.makeDefaultLibrary()
        
        // Initialize optimization components
        setupOptimizationComponents()
        
        // Configure Metal settings
        configureMetal()
    }
    
    /// Optimize graphics rendering for Vision Pro
    func optimizeForVisionPro() async throws -> VisionProOptimization {
        isOptimizing = true
        optimizationStatus = .optimizing
        optimizationProgress = 0.0
        
        defer {
            isOptimizing = false
            optimizationStatus = .completed
        }
        
        guard let device = device else {
            throw MetalError.deviceNotFound
        }
        
        // Step 1: Analyze current graphics performance
        optimizationProgress = 0.1
        let baselinePerformance = await analyzeGraphicsPerformance()
        
        // Step 2: Optimize render pipeline
        optimizationProgress = 0.3
        let optimizedPipeline = try await optimizeRenderPipeline()
        
        // Step 3: Optimize memory management
        optimizationProgress = 0.5
        let optimizedMemory = try await optimizeMemoryManagement()
        
        // Step 4: Optimize shaders
        optimizationProgress = 0.7
        let optimizedShaders = try await optimizeShaders()
        
        // Step 5: Validate optimization
        optimizationProgress = 0.9
        let optimizedPerformance = await validateGraphicsOptimization(baselinePerformance: baselinePerformance)
        
        // Step 6: Create optimization result
        optimizationProgress = 1.0
        let optimization = VisionProOptimization(
            renderPipeline: optimizedPipeline,
            memoryManagement: optimizedMemory,
            shaders: optimizedShaders,
            performance: optimizedPerformance,
            optimizationLevel: calculateOptimizationLevel(baselinePerformance, optimizedPerformance)
        )
        
        currentPerformance = optimizedPerformance
        return optimization
    }
    
    /// Optimize real-time health data visualization
    func optimizeHealthDataVisualization() async throws -> HealthDataVisualizationOptimization {
        isOptimizing = true
        optimizationStatus = .optimizing
        optimizationProgress = 0.0
        
        defer {
            isOptimizing = false
            optimizationStatus = .completed
        }
        
        // Step 1: Optimize for real-time rendering
        optimizationProgress = 0.2
        let realTimeOptimization = try await optimizeForRealTimeRendering()
        
        // Step 2: Optimize data visualization shaders
        optimizationProgress = 0.4
        let visualizationShaders = try await optimizeVisualizationShaders()
        
        // Step 3: Optimize data streaming
        optimizationProgress = 0.6
        let dataStreaming = try await optimizeDataStreaming()
        
        // Step 4: Optimize UI rendering
        optimizationProgress = 0.8
        let uiRendering = try await optimizeUIRendering()
        
        // Step 5: Create optimization result
        optimizationProgress = 1.0
        return HealthDataVisualizationOptimization(
            realTimeRendering: realTimeOptimization,
            visualizationShaders: visualizationShaders,
            dataStreaming: dataStreaming,
            uiRendering: uiRendering
        )
    }
    
    /// Get optimized graphics resource by name
    func getOptimizedResource(_ resourceName: String) -> OptimizedGraphicsResource? {
        return optimizationCache[resourceName]
    }
    
    /// Start graphics performance monitoring
    func startPerformanceMonitoring() {
        performanceMonitor?.startMonitoring()
    }
    
    /// Stop graphics performance monitoring
    func stopPerformanceMonitoring() {
        performanceMonitor?.stopMonitoring()
    }
    
    /// Get graphics performance history
    func getPerformanceHistory() -> [GraphicsPerformance] {
        return performanceHistory
    }
    
    /// Optimize for specific rendering workload
    func optimizeForWorkload(_ workload: RenderingWorkload) async throws -> WorkloadOptimization {
        switch workload {
        case .fractalVisuals:
            return try await optimizeFractalVisuals()
        case .healthDataCharts:
            return try await optimizeHealthDataCharts()
        case .biofeedbackRendering:
            return try await optimizeBiofeedbackRendering()
        case .environmentalVisuals:
            return try await optimizeEnvironmentalVisuals()
        }
    }
    
    /// Get optimization recommendations
    func getOptimizationRecommendations() -> [GraphicsOptimizationRecommendation] {
        return generateOptimizationRecommendations()
    }
    
    // MARK: - Private Methods
    
    private func setupMetalGraphicsOptimizer() {
        // Initialize optimization components
        renderPipelineOptimizer = RenderPipelineOptimizer()
        memoryOptimizer = MemoryOptimizer()
        shaderOptimizer = ShaderOptimizer()
        performanceMonitor = GraphicsPerformanceMonitor()
        
        // Setup performance monitoring
        setupPerformanceMonitoring()
        
        // Initialize Metal if available
        try? initializeMetal()
    }
    
    private func setupPerformanceMonitoring() {
        performanceMonitor?.performancePublisher
            .sink { [weak self] performance in
                self?.updatePerformanceHistory(performance)
            }
            .store(in: &cancellables)
    }
    
    private func setupOptimizationComponents() {
        guard let device = device else { return }
        
        renderPipelineOptimizer?.setup(with: device)
        memoryOptimizer?.setup(with: device)
        shaderOptimizer?.setup(with: device)
    }
    
    private func configureMetal() {
        guard let device = device else { return }
        
        // Configure Metal settings for optimal performance
        metalConfig.maxDrawCallsPerFrame = 1000
        metalConfig.preferredTextureFormat = .bgra8Unorm
        metalConfig.enableMultisampling = true
        metalConfig.maxTextureSize = 4096
        metalConfig.enableDepthTesting = true
        metalConfig.enableStencilTesting = false
    }
    
    private func analyzeGraphicsPerformance() async -> GraphicsPerformance {
        let startTime = CFAbsoluteTimeGetCurrent()
        
        // Perform graphics benchmark
        let frameTime = await performGraphicsBenchmark()
        let memoryUsage = getCurrentMemoryUsage()
        let gpuUtilization = getGPUUtilization()
        
        let endTime = CFAbsoluteTimeGetCurrent()
        let analysisTime = endTime - startTime
        
        return GraphicsPerformance(
            frameTime: frameTime,
            memoryUsage: memoryUsage,
            gpuUtilization: gpuUtilization,
            drawCalls: getDrawCallCount(),
            timestamp: Date()
        )
    }
    
    private func performGraphicsBenchmark() async -> Double {
        // Perform a simple graphics benchmark
        // This would measure frame rendering time
        return 0.016 // 60 FPS equivalent
    }
    
    private func getCurrentMemoryUsage() -> Int64 {
        // Use Metal API to estimate memory usage (platform-specific, example for iOS/macOS)
        #if targetEnvironment(simulator)
        return 0 // Metal memory queries not available in simulator
        #else
        if let device = device as? MTLDevice {
            // Use device.currentAllocatedSize if available (macOS 13+)
            if #available(macOS 13.0, iOS 16.0, *), let size = device.currentAllocatedSize {
                return Int64(size)
            }
        }
        return 0 // Fallback if not available
        #endif
    }
    
    private func getGPUUtilization() -> Double {
        // Use Metal Performance Shaders or system APIs for real GPU utilization
        #if canImport(MetalPerformanceShaders)
        // Example: Use MTLDevice's counters or MPS APIs if available
        // (Requires additional setup and entitlements)
        return queryGPUUtilizationFromSystem()
        #else
        return 0.0
        #endif
    }
    
    private func getDrawCallCount() -> Int {
        // Track draw calls via custom render command encoder wrapper
        return renderCommandEncoder?.drawCallCount ?? 0
    }
    
    private func optimizeRenderPipeline() async throws -> OptimizedRenderPipeline {
        guard let optimizer = renderPipelineOptimizer else {
            throw MetalError.optimizerNotAvailable
        }
        
        return try await optimizer.optimizePipeline()
    }
    
    private func optimizeMemoryManagement() async throws -> OptimizedMemoryManagement {
        guard let optimizer = memoryOptimizer else {
            throw MetalError.optimizerNotAvailable
        }
        
        return try await optimizer.optimizeMemory()
    }
    
    private func optimizeShaders() async throws -> OptimizedShaders {
        guard let optimizer = shaderOptimizer else {
            throw MetalError.optimizerNotAvailable
        }
        
        return try await optimizer.optimizeShaders()
    }
    
    private func validateGraphicsOptimization(baselinePerformance: GraphicsPerformance) async -> GraphicsPerformance {
        let optimizedPerformance = await analyzeGraphicsPerformance()
        
        // Validate that optimization improved performance
        let improvement = calculateGraphicsPerformanceImprovement(baseline: baselinePerformance, optimized: optimizedPerformance)
        
        if improvement.frameTimeImprovement < 0.1 {
            // Optimization didn't provide significant improvement, revert
            return baselinePerformance
        }
        
        return optimizedPerformance
    }
    
    private func calculateGraphicsPerformanceImprovement(baseline: GraphicsPerformance, optimized: GraphicsPerformance) -> GraphicsPerformanceImprovement {
        let frameTimeImprovement = (baseline.frameTime - optimized.frameTime) / baseline.frameTime
        let memoryImprovement = (baseline.memoryUsage - optimized.memoryUsage) / baseline.memoryUsage
        let gpuUtilizationImprovement = (baseline.gpuUtilization - optimized.gpuUtilization) / baseline.gpuUtilization
        
        return GraphicsPerformanceImprovement(
            frameTimeImprovement: frameTimeImprovement,
            memoryImprovement: memoryImprovement,
            gpuUtilizationImprovement: gpuUtilizationImprovement
        )
    }
    
    private func calculateOptimizationLevel(_ baseline: GraphicsPerformance, _ optimized: GraphicsPerformance) -> OptimizationLevel {
        let improvement = calculateGraphicsPerformanceImprovement(baseline: baseline, optimized: optimized)
        
        let totalImprovement = improvement.frameTimeImprovement + improvement.memoryImprovement + improvement.gpuUtilizationImprovement
        
        switch totalImprovement {
        case 0.0..<0.1: return .minimal
        case 0.1..<0.3: return .moderate
        case 0.3..<0.5: return .significant
        default: return .excellent
        }
    }
    
    private func optimizeForRealTimeRendering() async throws -> RealTimeRenderingOptimization {
        // Optimize for real-time rendering requirements
        return RealTimeRenderingOptimization(
            targetFrameRate: 60.0,
            maxFrameTime: 0.016,
            enableVSync: true,
            enableTripleBuffering: true
        )
    }
    
    private func optimizeVisualizationShaders() async throws -> VisualizationShaderOptimization {
        // Optimize shaders for health data visualization
        return VisualizationShaderOptimization(
            chartShaders: try await optimizeChartShaders(),
            graphShaders: try await optimizeGraphShaders(),
            metricShaders: try await optimizeMetricShaders()
        )
    }
    
    private func optimizeDataStreaming() async throws -> DataStreamingOptimization {
        // Optimize data streaming for real-time updates
        return DataStreamingOptimization(
            bufferSize: 1024,
            updateFrequency: 60.0,
            enableCompression: true,
            enableCaching: true
        )
    }
    
    private func optimizeUIRendering() async throws -> UIRenderingOptimization {
        // Optimize UI rendering
        return UIRenderingOptimization(
            enableLayerBacking: true,
            enableRasterization: false,
            enableAntialiasing: true,
            maxLayerCount: 100
        )
    }
    
    private func optimizeFractalVisuals() async throws -> WorkloadOptimization {
        // Optimize for fractal visualization rendering
        let fractalShaders = try await createFractalShaders()
        let fractalPipeline = try await createFractalPipeline()
        
        return WorkloadOptimization(
            type: .fractalVisuals,
            shaders: fractalShaders,
            pipeline: fractalPipeline,
            memoryRequirements: calculateFractalMemoryRequirements()
        )
    }
    
    private func optimizeHealthDataCharts() async throws -> WorkloadOptimization {
        // Optimize for health data chart rendering
        let chartShaders = try await createChartShaders()
        let chartPipeline = try await createChartPipeline()
        
        return WorkloadOptimization(
            type: .healthDataCharts,
            shaders: chartShaders,
            pipeline: chartPipeline,
            memoryRequirements: calculateChartMemoryRequirements()
        )
    }
    
    private func optimizeBiofeedbackRendering() async throws -> WorkloadOptimization {
        // Optimize for biofeedback visualization rendering
        let biofeedbackShaders = try await createBiofeedbackShaders()
        let biofeedbackPipeline = try await createBiofeedbackPipeline()
        
        return WorkloadOptimization(
            type: .biofeedbackRendering,
            shaders: biofeedbackShaders,
            pipeline: biofeedbackPipeline,
            memoryRequirements: calculateBiofeedbackMemoryRequirements()
        )
    }
    
    private func optimizeEnvironmentalVisuals() async throws -> WorkloadOptimization {
        // Optimize for environmental visualization rendering
        let environmentalShaders = try await createEnvironmentalShaders()
        let environmentalPipeline = try await createEnvironmentalPipeline()
        
        return WorkloadOptimization(
            type: .environmentalVisuals,
            shaders: environmentalShaders,
            pipeline: environmentalPipeline,
            memoryRequirements: calculateEnvironmentalMemoryRequirements()
        )
    }
    
    // MARK: - Shader Creation Methods (Placeholder implementations)
    
    private func createFractalShaders() async throws -> OptimizedShaders {
        return OptimizedShaders(vertexShader: "fractal_vertex", fragmentShader: "fractal_fragment")
    }
    
    private func createChartShaders() async throws -> OptimizedShaders {
        return OptimizedShaders(vertexShader: "chart_vertex", fragmentShader: "chart_fragment")
    }
    
    private func createBiofeedbackShaders() async throws -> OptimizedShaders {
        return OptimizedShaders(vertexShader: "biofeedback_vertex", fragmentShader: "biofeedback_fragment")
    }
    
    private func createEnvironmentalShaders() async throws -> OptimizedShaders {
        return OptimizedShaders(vertexShader: "environmental_vertex", fragmentShader: "environmental_fragment")
    }
    
    // MARK: - Pipeline Creation Methods (Placeholder implementations)
    
    private func createFractalPipeline() async throws -> OptimizedRenderPipeline {
        return OptimizedRenderPipeline(name: "fractal_pipeline", configuration: RenderPipelineConfiguration())
    }
    
    private func createChartPipeline() async throws -> OptimizedRenderPipeline {
        return OptimizedRenderPipeline(name: "chart_pipeline", configuration: RenderPipelineConfiguration())
    }
    
    private func createBiofeedbackPipeline() async throws -> OptimizedRenderPipeline {
        return OptimizedRenderPipeline(name: "biofeedback_pipeline", configuration: RenderPipelineConfiguration())
    }
    
    private func createEnvironmentalPipeline() async throws -> OptimizedRenderPipeline {
        return OptimizedRenderPipeline(name: "environmental_pipeline", configuration: RenderPipelineConfiguration())
    }
    
    // MARK: - Memory Requirements Calculation (Placeholder implementations)
    
    private func calculateFractalMemoryRequirements() -> MemoryRequirements {
        return MemoryRequirements(textureMemory: 50_000_000, bufferMemory: 10_000_000)
    }
    
    private func calculateChartMemoryRequirements() -> MemoryRequirements {
        return MemoryRequirements(textureMemory: 20_000_000, bufferMemory: 5_000_000)
    }
    
    private func calculateBiofeedbackMemoryRequirements() -> MemoryRequirements {
        return MemoryRequirements(textureMemory: 30_000_000, bufferMemory: 8_000_000)
    }
    
    private func calculateEnvironmentalMemoryRequirements() -> MemoryRequirements {
        return MemoryRequirements(textureMemory: 40_000_000, bufferMemory: 12_000_000)
    }
    
    private func updatePerformanceHistory(_ performance: GraphicsPerformance) {
        performanceHistory.append(performance)
        
        // Keep only recent history
        if performanceHistory.count > maxHistorySize {
            performanceHistory.removeFirst()
        }
        
        DispatchQueue.main.async { [weak self] in
            self?.currentPerformance = performance
        }
    }
    
    private func generateOptimizationRecommendations() -> [GraphicsOptimizationRecommendation] {
        var recommendations: [GraphicsOptimizationRecommendation] = []
        
        // Analyze performance history
        if let averagePerformance = calculateAverageGraphicsPerformance() {
            if averagePerformance.frameTime > 0.016 { // 60 FPS threshold
                recommendations.append(GraphicsOptimizationRecommendation(
                    type: .frameRate,
                    priority: .high,
                    description: "Frame rate is below 60 FPS. Consider reducing draw calls or optimizing shaders.",
                    estimatedImprovement: 0.3
                ))
            }
            
            if averagePerformance.memoryUsage > 200_000_000 { // 200MB
                recommendations.append(GraphicsOptimizationRecommendation(
                    type: .memoryUsage,
                    priority: .medium,
                    description: "Graphics memory usage is high. Consider texture compression or reducing texture quality.",
                    estimatedImprovement: 0.2
                ))
            }
            
            if averagePerformance.gpuUtilization > 0.8 { // 80%
                recommendations.append(GraphicsOptimizationRecommendation(
                    type: .gpuUtilization,
                    priority: .high,
                    description: "GPU utilization is high. Consider reducing rendering complexity.",
                    estimatedImprovement: 0.4
                ))
            }
        }
        
        return recommendations
    }
    
    private func calculateAverageGraphicsPerformance() -> GraphicsPerformance? {
        guard !performanceHistory.isEmpty else { return nil }
        
        let totalFrameTime = performanceHistory.reduce(0) { $0 + $1.frameTime }
        let totalMemoryUsage = performanceHistory.reduce(0) { $0 + $1.memoryUsage }
        let totalGPUUtilization = performanceHistory.reduce(0) { $0 + $1.gpuUtilization }
        
        let count = Double(performanceHistory.count)
        
        return GraphicsPerformance(
            frameTime: totalFrameTime / count,
            memoryUsage: totalMemoryUsage / Int64(count),
            gpuUtilization: totalGPUUtilization / count,
            drawCalls: performanceHistory.last?.drawCalls ?? 0,
            timestamp: Date()
        )
    }
    
    private func cleanup() {
        stopPerformanceMonitoring()
        cancellables.removeAll()
    }
}

// MARK: - Supporting Types

struct GraphicsPerformance {
    let frameTime: Double // seconds
    let memoryUsage: Int64 // bytes
    let gpuUtilization: Double // 0.0 - 1.0
    let drawCalls: Int
    let timestamp: Date
}

struct VisionProOptimization {
    let renderPipeline: OptimizedRenderPipeline
    let memoryManagement: OptimizedMemoryManagement
    let shaders: OptimizedShaders
    let performance: GraphicsPerformance
    let optimizationLevel: OptimizationLevel
}

struct HealthDataVisualizationOptimization {
    let realTimeRendering: RealTimeRenderingOptimization
    let visualizationShaders: VisualizationShaderOptimization
    let dataStreaming: DataStreamingOptimization
    let uiRendering: UIRenderingOptimization
}

struct WorkloadOptimization {
    let type: RenderingWorkload
    let shaders: OptimizedShaders
    let pipeline: OptimizedRenderPipeline
    let memoryRequirements: MemoryRequirements
}

enum RenderingWorkload: String, CaseIterable {
    case fractalVisuals = "Fractal Visuals"
    case healthDataCharts = "Health Data Charts"
    case biofeedbackRendering = "Biofeedback Rendering"
    case environmentalVisuals = "Environmental Visuals"
}

struct OptimizedGraphicsResource {
    let name: String
    let resource: Any
    let performance: GraphicsPerformance
}

struct GraphicsPerformanceImprovement {
    let frameTimeImprovement: Double
    let memoryImprovement: Double
    let gpuUtilizationImprovement: Double
}

struct GraphicsOptimizationRecommendation {
    let type: GraphicsOptimizationType
    let priority: RecommendationPriority
    let description: String
    let estimatedImprovement: Double
}

enum GraphicsOptimizationType: String, CaseIterable {
    case frameRate = "Frame Rate"
    case memoryUsage = "Memory Usage"
    case gpuUtilization = "GPU Utilization"
    case drawCalls = "Draw Calls"
}

struct MetalConfig {
    var maxDrawCallsPerFrame: Int = 1000
    var preferredTextureFormat: MTLPixelFormat = .bgra8Unorm
    var enableMultisampling: Bool = true
    var maxTextureSize: Int = 4096
    var enableDepthTesting: Bool = true
    var enableStencilTesting: Bool = false
}

// MARK: - Supporting Classes

class RenderPipelineOptimizer {
    func setup(with device: MTLDevice) {
        // Setup render pipeline optimizer
    }
    
    func optimizePipeline() async throws -> OptimizedRenderPipeline {
        return OptimizedRenderPipeline(name: "optimized_pipeline", configuration: RenderPipelineConfiguration())
    }
}

class MemoryOptimizer {
    func setup(with device: MTLDevice) {
        // Setup memory optimizer
    }
    
    func optimizeMemory() async throws -> OptimizedMemoryManagement {
        return OptimizedMemoryManagement(bufferSize: 1024, enableCompression: true)
    }
}

class ShaderOptimizer {
    func setup(with device: MTLDevice) {
        // Setup shader optimizer
    }
    
    func optimizeShaders() async throws -> OptimizedShaders {
        return OptimizedShaders(vertexShader: "optimized_vertex", fragmentShader: "optimized_fragment")
    }
}

class GraphicsPerformanceMonitor: ObservableObject {
    @Published var currentPerformance: GraphicsPerformance = GraphicsPerformance(
        frameTime: 0.016,
        memoryUsage: 100_000_000,
        gpuUtilization: 0.5,
        drawCalls: 100,
        timestamp: Date()
    )
    
    var performancePublisher: AnyPublisher<GraphicsPerformance, Never> {
        $currentPerformance.eraseToAnyPublisher()
    }
    
    func startMonitoring() {
        // Start real-time graphics performance monitoring
    }
    
    func stopMonitoring() {
        // Stop performance monitoring
    }
}

// MARK: - Additional Supporting Types

struct OptimizedRenderPipeline {
    let name: String
    let configuration: RenderPipelineConfiguration
}

struct RenderPipelineConfiguration {
    let vertexFunction: String = "vertex_main"
    let fragmentFunction: String = "fragment_main"
    let enableDepthTesting: Bool = true
    let enableBlending: Bool = true
}

struct OptimizedMemoryManagement {
    let bufferSize: Int
    let enableCompression: Bool
}

struct OptimizedShaders {
    let vertexShader: String
    let fragmentShader: String
}

struct RealTimeRenderingOptimization {
    let targetFrameRate: Double
    let maxFrameTime: Double
    let enableVSync: Bool
    let enableTripleBuffering: Bool
}

struct VisualizationShaderOptimization {
    let chartShaders: OptimizedShaders
    let graphShaders: OptimizedShaders
    let metricShaders: OptimizedShaders
}

struct DataStreamingOptimization {
    let bufferSize: Int
    let updateFrequency: Double
    let enableCompression: Bool
    let enableCaching: Bool
}

struct UIRenderingOptimization {
    let enableLayerBacking: Bool
    let enableRasterization: Bool
    let enableAntialiasing: Bool
    let maxLayerCount: Int
}

struct MemoryRequirements {
    let textureMemory: Int64
    let bufferMemory: Int64
}

enum MetalError: Error {
    case deviceNotFound
    case optimizerNotAvailable
    case compilationFailed
    case optimizationFailed
}

enum OptimizationStatus: String, CaseIterable {
    case idle = "Idle"
    case optimizing = "Optimizing"
    case completed = "Completed"
    case failed = "Failed"
}

enum OptimizationLevel: String, CaseIterable {
    case minimal = "Minimal"
    case moderate = "Moderate"
    case significant = "Significant"
    case excellent = "Excellent"
}

enum RecommendationPriority: String, CaseIterable {
    case low = "Low"
    case medium = "Medium"
    case high = "High"
}