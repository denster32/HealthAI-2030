import Metal
import MetalKit
import MetalPerformanceShaders
import MetalPerformanceShadersGraph
import Foundation

@available(iOS 18.0, macOS 15.0, tvOS 18.0, watchOS 11.0, visionOS 2.0, *)
class Metal4Configuration: NSObject, ObservableObject {
    
    // MARK: - Metal 4 Core Properties
    
    static let shared = Metal4Configuration()
    
    @Published var isInitialized = false
    @Published var supportedFeatures: [Metal4Feature] = []
    @Published var deviceCapabilities: DeviceCapabilities = DeviceCapabilities()
    @Published var performanceMetrics: Metal4PerformanceMetrics = Metal4PerformanceMetrics()
    
    // MARK: - Metal 4 Core Components
    
    private(set) var metalDevice: MTLDevice?
    private(set) var commandQueue: MTLCommandQueue?
    private(set) var library: MTLLibrary?
    
    // Metal Performance Shaders Graph
    private(set) var mpsGraph: MPSGraph?
    private(set) var mpsGraphExecutionDescriptor: MPSGraphExecutionDescriptor?
    
    // Advanced Metal 4 Features
    private(set) var meshShaderSupport: Bool = false
    private(set) var rayTracingSupport: Bool = false
    private(set) var variableRateShading: Bool = false
    private(set) var memorylessRenderTargets: Bool = false
    private(set) var argumentBufferTier: MTLArgumentBuffersTier = .tier1
    private(set) var resourceHeapSupport: Bool = false
    
    // Cross-Platform Compatibility
    private(set) var platformOptimizations: PlatformOptimizations = PlatformOptimizations()
    
    // MARK: - Initialization
    
    override init() {
        super.init()
        initializeMetal4()
    }
    
    private func initializeMetal4() {
        guard let device = MTLCreateSystemDefaultDevice() else {
            print("❌ Metal 4 not supported on this device")
            return
        }
        
        metalDevice = device
        commandQueue = device.makeCommandQueue()
        
        // Load Metal library
        library = device.makeDefaultLibrary()
        
        // Initialize Metal Performance Shaders Graph
        setupMPSGraph()
        
        // Detect device capabilities
        detectDeviceCapabilities()
        
        // Apply platform-specific optimizations
        applyPlatformOptimizations()
        
        // Initialize performance monitoring
        setupPerformanceMonitoring()
        
        DispatchQueue.main.async {
            self.isInitialized = true
        }
        
        print("✅ Metal 4 initialized successfully")
        print("📱 Device: \(device.name)")
        print("🚀 Features: \(supportedFeatures.map { $0.rawValue }.joined(separator: ", "))")
    }
    
    private func setupMPSGraph() {
        mpsGraph = MPSGraph()
        mpsGraphExecutionDescriptor = MPSGraphExecutionDescriptor()
        
        // Configure execution descriptor for optimal performance
        mpsGraphExecutionDescriptor?.enableGPUCapture = false
        mpsGraphExecutionDescriptor?.enableCommitAndWait = false
        mpsGraphExecutionDescriptor?.enableProfilingOpNames = false
        
        #if DEBUG
        mpsGraphExecutionDescriptor?.enableGPUCapture = true
        mpsGraphExecutionDescriptor?.enableProfilingOpNames = true
        #endif
    }
    
    private func detectDeviceCapabilities() {
        guard let device = metalDevice else { return }
        
        // Check Metal 4 specific features
        if device.supportsFamily(.apple9) || device.supportsFamily(.mac2) {
            supportedFeatures.append(.meshShaders)
            meshShaderSupport = true
        }
        
        if device.supportsRaytracing {
            supportedFeatures.append(.rayTracing)
            rayTracingSupport = true
        }
        
        if device.supportsFamily(.apple8) {
            supportedFeatures.append(.variableRateShading)
            variableRateShading = true
        }
        
        // Check argument buffer support
        argumentBufferTier = device.argumentBuffersSupport
        if argumentBufferTier.rawValue >= MTLArgumentBuffersTier.tier2.rawValue {
            supportedFeatures.append(.argumentBuffersTier2)
        }
        
        // Check resource heap support
        if device.hasUnifiedMemory {
            resourceHeapSupport = true
            supportedFeatures.append(.resourceHeaps)
        }
        
        // Check memoryless render targets
        if device.supportsFamily(.apple1) {
            memorylessRenderTargets = true
            supportedFeatures.append(.memorylessRenderTargets)
        }
        
        // Update device capabilities
        deviceCapabilities = DeviceCapabilities(
            name: device.name,
            maxThreadsPerThreadgroup: device.maxThreadsPerThreadgroup,
            maxBufferLength: device.maxBufferLength,
            maxTextureSize: device.maxTextureSize2D,
            supportsNonUniformThreadgroups: device.supportsFamily(.apple6),
            argumentBufferTier: argumentBufferTier,
            hasUnifiedMemory: device.hasUnifiedMemory,
            recommendedMaxWorkingSetSize: device.recommendedMaxWorkingSetSize,
            supportedFeatures: supportedFeatures
        )
    }
    
    private func applyPlatformOptimizations() {
        #if os(iOS)
        platformOptimizations.configureiOSOptimizations()
        #elseif os(macOS)
        platformOptimizations.configureMacOSOptimizations()
        #elseif os(tvOS)
        platformOptimizations.configureTVOSOptimizations()
        #elseif os(watchOS)
        platformOptimizations.configureWatchOSOptimizations()
        #elseif os(visionOS)
        platformOptimizations.configureVisionOSOptimizations()
        #endif
    }
    
    private func setupPerformanceMonitoring() {
        guard let device = metalDevice else { return }
        
        // Initialize performance counters
        performanceMetrics = Metal4PerformanceMetrics(
            gpuUtilization: 0.0,
            memoryUtilization: 0.0,
            thermalState: .nominal,
            frameTime: 0.0,
            commandBufferExecutionTime: 0.0
        )
        
        // Start performance monitoring
        startPerformanceMonitoring()
    }
    
    private func startPerformanceMonitoring() {
        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            self.updatePerformanceMetrics()
        }
    }
    
    private func updatePerformanceMetrics() {
        // Update performance metrics
        // This would integrate with Metal Performance HUD and GPU counters
        DispatchQueue.main.async {
            self.performanceMetrics.lastUpdateTime = Date()
        }
    }
    
    // MARK: - Public API
    
    func createCommandBuffer() -> MTLCommandBuffer? {
        return commandQueue?.makeCommandBuffer()
    }
    
    func createComputePipelineState(functionName: String) -> MTLComputePipelineState? {
        guard let device = metalDevice,
              let library = library,
              let function = library.makeFunction(name: functionName) else {
            return nil
        }
        
        do {
            return try device.makeComputePipelineState(function: function)
        } catch {
            print("❌ Failed to create compute pipeline state: \(error)")
            return nil
        }
    }
    
    func createRenderPipelineState(descriptor: MTLRenderPipelineDescriptor) -> MTLRenderPipelineState? {
        guard let device = metalDevice else { return nil }
        
        do {
            return try device.makeRenderPipelineState(descriptor: descriptor)
        } catch {
            print("❌ Failed to create render pipeline state: \(error)")
            return nil
        }
    }
    
    func createResourceHeap(size: Int) -> MTLHeap? {
        guard let device = metalDevice, resourceHeapSupport else { return nil }
        
        let descriptor = MTLHeapDescriptor()
        descriptor.size = size
        descriptor.type = .automatic
        descriptor.storageMode = .private
        
        return device.makeHeap(descriptor: descriptor)
    }
    
    func supportsFeature(_ feature: Metal4Feature) -> Bool {
        return supportedFeatures.contains(feature)
    }
}

// MARK: - Supporting Types

enum Metal4Feature: String, CaseIterable {
    case meshShaders = "Mesh Shaders"
    case rayTracing = "Ray Tracing"
    case variableRateShading = "Variable Rate Shading"
    case argumentBuffersTier2 = "Argument Buffers Tier 2"
    case resourceHeaps = "Resource Heaps"
    case memorylessRenderTargets = "Memoryless Render Targets"
    case mpsGraph = "Metal Performance Shaders Graph"
    case crossDeviceSync = "Cross-Device Synchronization"
}

struct DeviceCapabilities {
    let name: String
    let maxThreadsPerThreadgroup: MTLSize
    let maxBufferLength: Int
    let maxTextureSize: Int
    let supportsNonUniformThreadgroups: Bool
    let argumentBufferTier: MTLArgumentBuffersTier
    let hasUnifiedMemory: Bool
    let recommendedMaxWorkingSetSize: Int
    let supportedFeatures: [Metal4Feature]
    
    init() {
        self.name = ""
        self.maxThreadsPerThreadgroup = MTLSize(width: 0, height: 0, depth: 0)
        self.maxBufferLength = 0
        self.maxTextureSize = 0
        self.supportsNonUniformThreadgroups = false
        self.argumentBufferTier = .tier1
        self.hasUnifiedMemory = false
        self.recommendedMaxWorkingSetSize = 0
        self.supportedFeatures = []
    }
    
    init(name: String, maxThreadsPerThreadgroup: MTLSize, maxBufferLength: Int, maxTextureSize: Int, supportsNonUniformThreadgroups: Bool, argumentBufferTier: MTLArgumentBuffersTier, hasUnifiedMemory: Bool, recommendedMaxWorkingSetSize: Int, supportedFeatures: [Metal4Feature]) {
        self.name = name
        self.maxThreadsPerThreadgroup = maxThreadsPerThreadgroup
        self.maxBufferLength = maxBufferLength
        self.maxTextureSize = maxTextureSize
        self.supportsNonUniformThreadgroups = supportsNonUniformThreadgroups
        self.argumentBufferTier = argumentBufferTier
        self.hasUnifiedMemory = hasUnifiedMemory
        self.recommendedMaxWorkingSetSize = recommendedMaxWorkingSetSize
        self.supportedFeatures = supportedFeatures
    }
}

struct Metal4PerformanceMetrics {
    var gpuUtilization: Double
    var memoryUtilization: Double
    var thermalState: ProcessInfo.ThermalState
    var frameTime: TimeInterval
    var commandBufferExecutionTime: TimeInterval
    var lastUpdateTime: Date
    
    init() {
        self.gpuUtilization = 0.0
        self.memoryUtilization = 0.0
        self.thermalState = .nominal
        self.frameTime = 0.0
        self.commandBufferExecutionTime = 0.0
        self.lastUpdateTime = Date()
    }
    
    init(gpuUtilization: Double, memoryUtilization: Double, thermalState: ProcessInfo.ThermalState, frameTime: TimeInterval, commandBufferExecutionTime: TimeInterval) {
        self.gpuUtilization = gpuUtilization
        self.memoryUtilization = memoryUtilization
        self.thermalState = thermalState
        self.frameTime = frameTime
        self.commandBufferExecutionTime = commandBufferExecutionTime
        self.lastUpdateTime = Date()
    }
}

struct PlatformOptimizations {
    var iOSOptimizations: iOSOptimizations = iOSOptimizations()
    var macOSOptimizations: MacOSOptimizations = MacOSOptimizations()
    var tvOSOptimizations: TVOSOptimizations = TVOSOptimizations()
    var watchOSOptimizations: WatchOSOptimizations = WatchOSOptimizations()
    var visionOSOptimizations: VisionOSOptimizations = VisionOSOptimizations()
    
    mutating func configureiOSOptimizations() {
        iOSOptimizations.enableTileBasedDeferredRendering = true
        iOSOptimizations.useMemorylessRenderTargets = true
        iOSOptimizations.enableDynamicLibraryLoading = true
    }
    
    mutating func configureMacOSOptimizations() {
        macOSOptimizations.enableArgumentBuffersTier2 = true
        macOSOptimizations.useResourceHeaps = true
        macOSOptimizations.enableRayTracing = true
    }
    
    mutating func configureTVOSOptimizations() {
        tvOSOptimizations.optimizeForLargeScreen = true
        tvOSOptimizations.enableHighFrameRate = true
        tvOSOptimizations.useAdvancedShading = true
    }
    
    mutating func configureWatchOSOptimizations() {
        watchOSOptimizations.enablePowerEfficiency = true
        watchOSOptimizations.useMinimalResources = true
        watchOSOptimizations.optimizeForSmallScreen = true
    }
    
    mutating func configureVisionOSOptimizations() {
        visionOSOptimizations.enableSpatialRendering = true
        visionOSOptimizations.use3DRenderingPipeline = true
        visionOSOptimizations.enableEyeTracking = true
    }
}

struct iOSOptimizations {
    var enableTileBasedDeferredRendering: Bool = false
    var useMemorylessRenderTargets: Bool = false
    var enableDynamicLibraryLoading: Bool = false
}

struct MacOSOptimizations {
    var enableArgumentBuffersTier2: Bool = false
    var useResourceHeaps: Bool = false
    var enableRayTracing: Bool = false
}

struct TVOSOptimizations {
    var optimizeForLargeScreen: Bool = false
    var enableHighFrameRate: Bool = false
    var useAdvancedShading: Bool = false
}

struct WatchOSOptimizations {
    var enablePowerEfficiency: Bool = false
    var useMinimalResources: Bool = false
    var optimizeForSmallScreen: Bool = false
}

struct VisionOSOptimizations {
    var enableSpatialRendering: Bool = false
    var use3DRenderingPipeline: Bool = false
    var enableEyeTracking: Bool = false
}