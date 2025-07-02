import Foundation
import SwiftUI
import Metal
import MetalKit
import simd
import os.log

/// Metal-accelerated chart rendering for enhanced iPad visualizations
@MainActor
class MetalChartRenderer: NSObject, ObservableObject {
    static let shared = MetalChartRenderer()
    
    @Published var isRendering = false
    @Published var renderingProgress: Double = 0.0
    @Published var framesPerSecond: Double = 60.0
    @Published var renderingEfficiency: Double = 0.0
    
    // Metal components
    private let metalDevice: MTLDevice?
    private let metalCommandQueue: MTLCommandQueue?
    private let metalLibrary: MTLLibrary?
    
    // Render pipeline states
    private var lineChartPipeline: MTLRenderPipelineState?
    private var barChartPipeline: MTLRenderPipelineState?
    private var areaChartPipeline: MTLRenderPipelineState?
    private var scatterPlotPipeline: MTLRenderPipelineState?
    
    // Performance optimization
    private let advancedMetalOptimizer = AdvancedMetalOptimizer.shared
    private var renderingMetrics = ChartRenderingMetrics()
    
    // Chart data buffers
    private var vertexBuffers: [String: MTLBuffer] = [:]
    private var indexBuffers: [String: MTLBuffer] = [:]
    private var uniformBuffers: [String: MTLBuffer] = [:]
    
    private override init() {
        self.metalDevice = MTLCreateSystemDefaultDevice()
        self.metalCommandQueue = metalDevice?.makeCommandQueue()
        self.metalLibrary = metalDevice?.makeDefaultLibrary()
        
        super.init()
        
        setupMetalRenderPipelines()
        Logger.info("MetalChartRenderer initialized with Metal support: \(metalDevice != nil)", log: Logger.performance)
    }
    
    // MARK: - Setup
    
    private func setupMetalRenderPipelines() {
        guard let device = metalDevice, let library = metalLibrary else {
            Logger.warning("Metal device or library not available for chart rendering", log: Logger.performance)
            return
        }
        
        do {
            // Create render pipeline states for different chart types
            lineChartPipeline = try createRenderPipeline(device: device, library: library, vertexFunction: "lineChartVertex", fragmentFunction: "lineChartFragment")
            barChartPipeline = try createRenderPipeline(device: device, library: library, vertexFunction: "barChartVertex", fragmentFunction: "barChartFragment")
            areaChartPipeline = try createRenderPipeline(device: device, library: library, vertexFunction: "areaChartVertex", fragmentFunction: "areaChartFragment")
            scatterPlotPipeline = try createRenderPipeline(device: device, library: library, vertexFunction: "scatterPlotVertex", fragmentFunction: "scatterPlotFragment")
            
            Logger.success("Metal chart render pipelines initialized", log: Logger.performance)
        } catch {
            Logger.error("Failed to setup Metal chart render pipelines: \(error.localizedDescription)", log: Logger.performance)
        }
    }
    
    private func createRenderPipeline(device: MTLDevice, library: MTLLibrary, vertexFunction: String, fragmentFunction: String) throws -> MTLRenderPipelineState {
        let pipelineDescriptor = MTLRenderPipelineDescriptor()
        
        pipelineDescriptor.vertexFunction = library.makeFunction(name: vertexFunction)
        pipelineDescriptor.fragmentFunction = library.makeFunction(name: fragmentFunction)
        
        // Configure color attachment
        pipelineDescriptor.colorAttachments[0].pixelFormat = .bgra8Unorm
        pipelineDescriptor.colorAttachments[0].isBlendingEnabled = true
        pipelineDescriptor.colorAttachments[0].rgbBlendOperation = .add
        pipelineDescriptor.colorAttachments[0].alphaBlendOperation = .add
        pipelineDescriptor.colorAttachments[0].sourceRGBBlendFactor = .sourceAlpha
        pipelineDescriptor.colorAttachments[0].sourceAlphaBlendFactor = .sourceAlpha
        pipelineDescriptor.colorAttachments[0].destinationRGBBlendFactor = .oneMinusSourceAlpha
        pipelineDescriptor.colorAttachments[0].destinationAlphaBlendFactor = .oneMinusSourceAlpha
        
        return try device.makeRenderPipelineState(descriptor: pipelineDescriptor)
    }
    
    // MARK: - Public Chart Rendering Methods
    
    /// Render line chart with Metal acceleration
    func renderLineChart(data: [ChartDataPoint], size: CGSize, style: LineChartStyle) async -> MTKView? {
        guard let device = metalDevice, let commandQueue = metalCommandQueue, let pipeline = lineChartPipeline else {
            return await fallbackLineChartRendering(data: data, size: size, style: style)
        }
        
        await MainActor.run {
            isRendering = true
            renderingProgress = 0.1
        }
        
        let startTime = CFAbsoluteTimeGetCurrent()
        
        do {
            let chartView = try await metalRenderLineChart(
                data: data,
                size: size,
                style: style,
                device: device,
                commandQueue: commandQueue,
                pipeline: pipeline
            )
            
            let renderTime = CFAbsoluteTimeGetCurrent() - startTime
            await recordRenderingMetrics(chartType: "LineChart", duration: renderTime, dataPoints: data.count)
            
            await MainActor.run {
                isRendering = false
                renderingProgress = 1.0
            }
            
            return chartView
        } catch {
            Logger.error("Metal line chart rendering failed: \(error.localizedDescription)", log: Logger.performance)
            return await fallbackLineChartRendering(data: data, size: size, style: style)
        }
    }
    
    /// Render bar chart with Metal acceleration
    func renderBarChart(data: [ChartDataPoint], size: CGSize, style: BarChartStyle) async -> MTKView? {
        guard let device = metalDevice, let commandQueue = metalCommandQueue, let pipeline = barChartPipeline else {
            return await fallbackBarChartRendering(data: data, size: size, style: style)
        }
        
        await MainActor.run {
            isRendering = true
            renderingProgress = 0.2
        }
        
        let startTime = CFAbsoluteTimeGetCurrent()
        
        do {
            let chartView = try await metalRenderBarChart(
                data: data,
                size: size,
                style: style,
                device: device,
                commandQueue: commandQueue,
                pipeline: pipeline
            )
            
            let renderTime = CFAbsoluteTimeGetCurrent() - startTime
            await recordRenderingMetrics(chartType: "BarChart", duration: renderTime, dataPoints: data.count)
            
            await MainActor.run {
                isRendering = false
                renderingProgress = 1.0
            }
            
            return chartView
        } catch {
            Logger.error("Metal bar chart rendering failed: \(error.localizedDescription)", log: Logger.performance)
            return await fallbackBarChartRendering(data: data, size: size, style: style)
        }
    }
    
    /// Render area chart with Metal acceleration
    func renderAreaChart(data: [ChartDataPoint], size: CGSize, style: AreaChartStyle) async -> MTKView? {
        guard let device = metalDevice, let commandQueue = metalCommandQueue, let pipeline = areaChartPipeline else {
            return await fallbackAreaChartRendering(data: data, size: size, style: style)
        }
        
        await MainActor.run {
            isRendering = true
            renderingProgress = 0.3
        }
        
        let startTime = CFAbsoluteTimeGetCurrent()
        
        do {
            let chartView = try await metalRenderAreaChart(
                data: data,
                size: size,
                style: style,
                device: device,
                commandQueue: commandQueue,
                pipeline: pipeline
            )
            
            let renderTime = CFAbsoluteTimeGetCurrent() - startTime
            await recordRenderingMetrics(chartType: "AreaChart", duration: renderTime, dataPoints: data.count)
            
            await MainActor.run {
                isRendering = false
                renderingProgress = 1.0
            }
            
            return chartView
        } catch {
            Logger.error("Metal area chart rendering failed: \(error.localizedDescription)", log: Logger.performance)
            return await fallbackAreaChartRendering(data: data, size: size, style: style)
        }
    }
    
    /// Render real-time chart with streaming data
    func renderRealTimeChart(data: [ChartDataPoint], size: CGSize, style: RealTimeChartStyle) async -> MTKView? {
        guard let device = metalDevice, let commandQueue = metalCommandQueue else {
            return await fallbackRealTimeChartRendering(data: data, size: size, style: style)
        }
        
        await MainActor.run {
            isRendering = true
            renderingProgress = 0.4
        }
        
        let startTime = CFAbsoluteTimeGetCurrent()
        
        do {
            let chartView = try await metalRenderRealTimeChart(
                data: data,
                size: size,
                style: style,
                device: device,
                commandQueue: commandQueue
            )
            
            let renderTime = CFAbsoluteTimeGetCurrent() - startTime
            await recordRenderingMetrics(chartType: "RealTimeChart", duration: renderTime, dataPoints: data.count)
            
            await MainActor.run {
                isRendering = false
                renderingProgress = 1.0
                framesPerSecond = min(120, 1.0 / renderTime)
            }
            
            return chartView
        } catch {
            Logger.error("Metal real-time chart rendering failed: \(error.localizedDescription)", log: Logger.performance)
            return await fallbackRealTimeChartRendering(data: data, size: size, style: style)
        }
    }
    
    // MARK: - Metal Rendering Implementation
    
    private func metalRenderLineChart(data: [ChartDataPoint], size: CGSize, style: LineChartStyle, device: MTLDevice, commandQueue: MTLCommandQueue, pipeline: MTLRenderPipelineState) async throws -> MTKView {
        
        // Create vertex buffer for line chart
        let vertices = createLineChartVertices(data: data, size: size)
        guard let vertexBuffer = device.makeBuffer(bytes: vertices, length: vertices.count * MemoryLayout<ChartVertex>.size, options: .storageModeShared) else {
            throw MetalChartError.bufferCreationFailed
        }
        
        // Create uniform buffer for chart styling
        var uniforms = LineChartUniforms(
            color: style.lineColor.metalFloat4,
            lineWidth: Float(style.lineWidth),
            smoothing: style.smoothing ? 1.0 : 0.0,
            animation: Float(style.animationProgress)
        )
        
        guard let uniformBuffer = device.makeBuffer(bytes: &uniforms, length: MemoryLayout<LineChartUniforms>.size, options: .storageModeShared) else {
            throw MetalChartError.bufferCreationFailed
        }
        
        // Create MTKView for rendering
        let mtkView = MTKView(frame: CGRect(origin: .zero, size: size), device: device)
        mtkView.delegate = LineChartRenderer(pipeline: pipeline, vertexBuffer: vertexBuffer, uniformBuffer: uniformBuffer, vertexCount: vertices.count)
        mtkView.isPaused = false
        mtkView.enableSetNeedsDisplay = true
        
        return mtkView
    }
    
    private func metalRenderBarChart(data: [ChartDataPoint], size: CGSize, style: BarChartStyle, device: MTLDevice, commandQueue: MTLCommandQueue, pipeline: MTLRenderPipelineState) async throws -> MTKView {
        
        // Create vertex buffer for bar chart
        let vertices = createBarChartVertices(data: data, size: size, style: style)
        guard let vertexBuffer = device.makeBuffer(bytes: vertices, length: vertices.count * MemoryLayout<ChartVertex>.size, options: .storageModeShared) else {
            throw MetalChartError.bufferCreationFailed
        }
        
        // Create uniform buffer for chart styling
        var uniforms = BarChartUniforms(
            barColor: style.barColor.metalFloat4,
            borderColor: style.borderColor.metalFloat4,
            barSpacing: Float(style.barSpacing),
            cornerRadius: Float(style.cornerRadius),
            animation: Float(style.animationProgress)
        )
        
        guard let uniformBuffer = device.makeBuffer(bytes: &uniforms, length: MemoryLayout<BarChartUniforms>.size, options: .storageModeShared) else {
            throw MetalChartError.bufferCreationFailed
        }
        
        // Create MTKView for rendering
        let mtkView = MTKView(frame: CGRect(origin: .zero, size: size), device: device)
        mtkView.delegate = BarChartRenderer(pipeline: pipeline, vertexBuffer: vertexBuffer, uniformBuffer: uniformBuffer, vertexCount: vertices.count)
        mtkView.isPaused = false
        mtkView.enableSetNeedsDisplay = true
        
        return mtkView
    }
    
    private func metalRenderAreaChart(data: [ChartDataPoint], size: CGSize, style: AreaChartStyle, device: MTLDevice, commandQueue: MTLCommandQueue, pipeline: MTLRenderPipelineState) async throws -> MTKView {
        
        // Create vertex buffer for area chart
        let vertices = createAreaChartVertices(data: data, size: size)
        guard let vertexBuffer = device.makeBuffer(bytes: vertices, length: vertices.count * MemoryLayout<ChartVertex>.size, options: .storageModeShared) else {
            throw MetalChartError.bufferCreationFailed
        }
        
        // Create uniform buffer for chart styling
        var uniforms = AreaChartUniforms(
            fillColor: style.fillColor.metalFloat4,
            strokeColor: style.strokeColor.metalFloat4,
            gradient: style.gradient ? 1.0 : 0.0,
            opacity: Float(style.opacity),
            animation: Float(style.animationProgress)
        )
        
        guard let uniformBuffer = device.makeBuffer(bytes: &uniforms, length: MemoryLayout<AreaChartUniforms>.size, options: .storageModeShared) else {
            throw MetalChartError.bufferCreationFailed
        }
        
        // Create MTKView for rendering
        let mtkView = MTKView(frame: CGRect(origin: .zero, size: size), device: device)
        mtkView.delegate = AreaChartRenderer(pipeline: pipeline, vertexBuffer: vertexBuffer, uniformBuffer: uniformBuffer, vertexCount: vertices.count)
        mtkView.isPaused = false
        mtkView.enableSetNeedsDisplay = true
        
        return mtkView
    }
    
    private func metalRenderRealTimeChart(data: [ChartDataPoint], size: CGSize, style: RealTimeChartStyle, device: MTLDevice, commandQueue: MTLCommandQueue) async throws -> MTKView {
        
        // Use line chart pipeline for real-time rendering
        guard let pipeline = lineChartPipeline else {
            throw MetalChartError.pipelineNotFound
        }
        
        // Create streaming vertex buffer
        let vertices = createStreamingChartVertices(data: data, size: size, style: style)
        guard let vertexBuffer = device.makeBuffer(bytes: vertices, length: vertices.count * MemoryLayout<ChartVertex>.size, options: .storageModeShared) else {
            throw MetalChartError.bufferCreationFailed
        }
        
        // Create uniform buffer for real-time styling
        var uniforms = RealTimeChartUniforms(
            lineColor: style.lineColor.metalFloat4,
            backgroundColor: style.backgroundColor.metalFloat4,
            scrollSpeed: Float(style.scrollSpeed),
            fadeEffect: style.fadeEffect ? 1.0 : 0.0,
            timeWindow: Float(style.timeWindow)
        )
        
        guard let uniformBuffer = device.makeBuffer(bytes: &uniforms, length: MemoryLayout<RealTimeChartUniforms>.size, options: .storageModeShared) else {
            throw MetalChartError.bufferCreationFailed
        }
        
        // Create MTKView for real-time rendering
        let mtkView = MTKView(frame: CGRect(origin: .zero, size: size), device: device)
        mtkView.delegate = RealTimeChartRenderer(
            pipeline: pipeline,
            vertexBuffer: vertexBuffer,
            uniformBuffer: uniformBuffer,
            vertexCount: vertices.count,
            device: device
        )
        mtkView.isPaused = false
        mtkView.preferredFramesPerSecond = 60
        mtkView.enableSetNeedsDisplay = false // Use preferredFramesPerSecond for real-time
        
        return mtkView
    }
    
    // MARK: - Vertex Creation Methods
    
    private func createLineChartVertices(data: [ChartDataPoint], size: CGSize) -> [ChartVertex] {
        guard !data.isEmpty else { return [] }
        
        let xScale = Float(size.width) / Float(data.count - 1)
        let maxY = data.map { $0.value }.max() ?? 1.0
        let minY = data.map { $0.value }.min() ?? 0.0
        let yRange = maxY - minY
        let yScale = Float(size.height) / Float(yRange)
        
        return data.enumerated().map { index, point in
            let x = Float(index) * xScale
            let y = Float(point.value - minY) * yScale
            return ChartVertex(position: simd_float2(x, y), color: simd_float4(1.0, 1.0, 1.0, 1.0))
        }
    }
    
    private func createBarChartVertices(data: [ChartDataPoint], size: CGSize, style: BarChartStyle) -> [ChartVertex] {
        guard !data.isEmpty else { return [] }
        
        let barWidth = Float(size.width) / Float(data.count) * (1.0 - Float(style.barSpacing))
        let spacing = Float(size.width) / Float(data.count) * Float(style.barSpacing)
        let maxY = data.map { $0.value }.max() ?? 1.0
        let yScale = Float(size.height) / Float(maxY)
        
        var vertices: [ChartVertex] = []
        
        for (index, point) in data.enumerated() {
            let x = Float(index) * (barWidth + spacing)
            let height = Float(point.value) * yScale
            
            // Create rectangle vertices for each bar (2 triangles = 6 vertices)
            let barVertices = [
                ChartVertex(position: simd_float2(x, 0), color: style.barColor.metalFloat4),
                ChartVertex(position: simd_float2(x + barWidth, 0), color: style.barColor.metalFloat4),
                ChartVertex(position: simd_float2(x, height), color: style.barColor.metalFloat4),
                ChartVertex(position: simd_float2(x + barWidth, 0), color: style.barColor.metalFloat4),
                ChartVertex(position: simd_float2(x + barWidth, height), color: style.barColor.metalFloat4),
                ChartVertex(position: simd_float2(x, height), color: style.barColor.metalFloat4)
            ]
            
            vertices.append(contentsOf: barVertices)
        }
        
        return vertices
    }
    
    private func createAreaChartVertices(data: [ChartDataPoint], size: CGSize) -> [ChartVertex] {
        guard !data.isEmpty else { return [] }
        
        let xScale = Float(size.width) / Float(data.count - 1)
        let maxY = data.map { $0.value }.max() ?? 1.0
        let minY = data.map { $0.value }.min() ?? 0.0
        let yRange = maxY - minY
        let yScale = Float(size.height) / Float(yRange)
        
        var vertices: [ChartVertex] = []
        
        // Create triangulated area fill
        for i in 0..<(data.count - 1) {
            let x1 = Float(i) * xScale
            let x2 = Float(i + 1) * xScale
            let y1 = Float(data[i].value - minY) * yScale
            let y2 = Float(data[i + 1].value - minY) * yScale
            
            // Create triangles for area fill
            let areaVertices = [
                ChartVertex(position: simd_float2(x1, 0), color: simd_float4(0.5, 0.8, 1.0, 0.3)),
                ChartVertex(position: simd_float2(x2, 0), color: simd_float4(0.5, 0.8, 1.0, 0.3)),
                ChartVertex(position: simd_float2(x1, y1), color: simd_float4(0.5, 0.8, 1.0, 0.6)),
                ChartVertex(position: simd_float2(x2, 0), color: simd_float4(0.5, 0.8, 1.0, 0.3)),
                ChartVertex(position: simd_float2(x2, y2), color: simd_float4(0.5, 0.8, 1.0, 0.6)),
                ChartVertex(position: simd_float2(x1, y1), color: simd_float4(0.5, 0.8, 1.0, 0.6))
            ]
            
            vertices.append(contentsOf: areaVertices)
        }
        
        return vertices
    }
    
    private func createStreamingChartVertices(data: [ChartDataPoint], size: CGSize, style: RealTimeChartStyle) -> [ChartVertex] {
        guard !data.isEmpty else { return [] }
        
        // Use sliding window for real-time data
        let windowSize = min(data.count, Int(style.timeWindow))
        let recentData = Array(data.suffix(windowSize))
        
        let xScale = Float(size.width) / Float(windowSize - 1)
        let maxY = recentData.map { $0.value }.max() ?? 1.0
        let minY = recentData.map { $0.value }.min() ?? 0.0
        let yRange = maxY - minY
        let yScale = Float(size.height) / Float(yRange)
        
        return recentData.enumerated().map { index, point in
            let x = Float(index) * xScale
            let y = Float(point.value - minY) * yScale
            let alpha = style.fadeEffect ? Float(index) / Float(windowSize) : 1.0
            return ChartVertex(position: simd_float2(x, y), color: simd_float4(1.0, 1.0, 1.0, alpha))
        }
    }
    
    // MARK: - Fallback Rendering
    
    private func fallbackLineChartRendering(data: [ChartDataPoint], size: CGSize, style: LineChartStyle) async -> MTKView? {
        Logger.info("Using fallback rendering for line chart", log: Logger.performance)
        // Implement SwiftUI-based fallback rendering
        return nil
    }
    
    private func fallbackBarChartRendering(data: [ChartDataPoint], size: CGSize, style: BarChartStyle) async -> MTKView? {
        Logger.info("Using fallback rendering for bar chart", log: Logger.performance)
        return nil
    }
    
    private func fallbackAreaChartRendering(data: [ChartDataPoint], size: CGSize, style: AreaChartStyle) async -> MTKView? {
        Logger.info("Using fallback rendering for area chart", log: Logger.performance)
        return nil
    }
    
    private func fallbackRealTimeChartRendering(data: [ChartDataPoint], size: CGSize, style: RealTimeChartStyle) async -> MTKView? {
        Logger.info("Using fallback rendering for real-time chart", log: Logger.performance)
        return nil
    }
    
    // MARK: - Performance Tracking
    
    private func recordRenderingMetrics(chartType: String, duration: TimeInterval, dataPoints: Int) async {
        renderingMetrics.recordRender(chartType: chartType, duration: duration, dataPoints: dataPoints)
        
        await MainActor.run {
            renderingEfficiency = min(1.0, max(0.0, 1.0 - (duration / 0.016))) // 16ms target for 60fps
        }
        
        await advancedMetalOptimizer.recordModelInference(duration: duration)
        
        Logger.debug("Chart rendering - \(chartType): \(String(format: \"%.3f\", duration))s for \(dataPoints) points", log: Logger.performance)
    }
    
    // MARK: - Public API
    
    func getRenderingMetrics() -> ChartRenderingMetrics {
        return renderingMetrics
    }
    
    func isMetalAccelerationAvailable() -> Bool {
        return metalDevice != nil && metalCommandQueue != nil
    }
}

// MARK: - Data Models

struct ChartDataPoint {
    let timestamp: Date
    let value: Double
    let label: String?
    
    init(timestamp: Date = Date(), value: Double, label: String? = nil) {
        self.timestamp = timestamp
        self.value = value
        self.label = label
    }
}

struct ChartVertex {
    let position: simd_float2
    let color: simd_float4
}

// Chart Style Definitions
struct LineChartStyle {
    let lineColor: Color
    let lineWidth: CGFloat
    let smoothing: Bool
    let animationProgress: Double
    
    init(lineColor: Color = .blue, lineWidth: CGFloat = 2.0, smoothing: Bool = true, animationProgress: Double = 1.0) {
        self.lineColor = lineColor
        self.lineWidth = lineWidth
        self.smoothing = smoothing
        self.animationProgress = animationProgress
    }
}

struct BarChartStyle {
    let barColor: Color
    let borderColor: Color
    let barSpacing: CGFloat
    let cornerRadius: CGFloat
    let animationProgress: Double
    
    init(barColor: Color = .blue, borderColor: Color = .clear, barSpacing: CGFloat = 0.1, cornerRadius: CGFloat = 4.0, animationProgress: Double = 1.0) {
        self.barColor = barColor
        self.borderColor = borderColor
        self.barSpacing = barSpacing
        self.cornerRadius = cornerRadius
        self.animationProgress = animationProgress
    }
}

struct AreaChartStyle {
    let fillColor: Color
    let strokeColor: Color
    let gradient: Bool
    let opacity: Double
    let animationProgress: Double
    
    init(fillColor: Color = .blue.opacity(0.3), strokeColor: Color = .blue, gradient: Bool = true, opacity: Double = 0.6, animationProgress: Double = 1.0) {
        self.fillColor = fillColor
        self.strokeColor = strokeColor
        self.gradient = gradient
        self.opacity = opacity
        self.animationProgress = animationProgress
    }
}

struct RealTimeChartStyle {
    let lineColor: Color
    let backgroundColor: Color
    let scrollSpeed: Double
    let fadeEffect: Bool
    let timeWindow: Double
    
    init(lineColor: Color = .green, backgroundColor: Color = .black.opacity(0.1), scrollSpeed: Double = 1.0, fadeEffect: Bool = true, timeWindow: Double = 60.0) {
        self.lineColor = lineColor
        self.backgroundColor = backgroundColor
        self.scrollSpeed = scrollSpeed
        self.fadeEffect = fadeEffect
        self.timeWindow = timeWindow
    }
}

// Metal Uniform Structures
struct LineChartUniforms {
    let color: simd_float4
    let lineWidth: Float
    let smoothing: Float
    let animation: Float
}

struct BarChartUniforms {
    let barColor: simd_float4
    let borderColor: simd_float4
    let barSpacing: Float
    let cornerRadius: Float
    let animation: Float
}

struct AreaChartUniforms {
    let fillColor: simd_float4
    let strokeColor: simd_float4
    let gradient: Float
    let opacity: Float
    let animation: Float
}

struct RealTimeChartUniforms {
    let lineColor: simd_float4
    let backgroundColor: simd_float4
    let scrollSpeed: Float
    let fadeEffect: Float
    let timeWindow: Float
}

struct ChartRenderingMetrics {
    private var renderCounts: [String: Int] = [:]
    private var averageDurations: [String: TimeInterval] = [:]
    private var totalDataPoints: [String: Int] = [:]
    
    mutating func recordRender(chartType: String, duration: TimeInterval, dataPoints: Int) {
        renderCounts[chartType, default: 0] += 1
        averageDurations[chartType] = ((averageDurations[chartType] ?? 0) * Double(renderCounts[chartType]! - 1) + duration) / Double(renderCounts[chartType]!)
        totalDataPoints[chartType, default: 0] += dataPoints
    }
    
    func getAverageRenderTime(for chartType: String) -> TimeInterval {
        return averageDurations[chartType] ?? 0
    }
    
    func getTotalRenders(for chartType: String) -> Int {
        return renderCounts[chartType] ?? 0
    }
    
    func getTotalDataPoints(for chartType: String) -> Int {
        return totalDataPoints[chartType] ?? 0
    }
}

enum MetalChartError: Error {
    case bufferCreationFailed
    case pipelineNotFound
    case deviceNotAvailable
    case renderingFailed
}

// MARK: - Color Extensions

extension Color {
    var metalFloat4: simd_float4 {
        guard let cgColor = self.cgColor else {
            return simd_float4(1.0, 1.0, 1.0, 1.0)
        }
        
        let components = cgColor.components ?? [1.0, 1.0, 1.0, 1.0]
        
        if components.count >= 4 {
            return simd_float4(Float(components[0]), Float(components[1]), Float(components[2]), Float(components[3]))
        } else if components.count >= 3 {
            return simd_float4(Float(components[0]), Float(components[1]), Float(components[2]), 1.0)
        } else {
            return simd_float4(1.0, 1.0, 1.0, 1.0)
        }
    }
}

// MARK: - Metal Chart Renderers

class LineChartRenderer: NSObject, MTKViewDelegate {
    let pipeline: MTLRenderPipelineState
    let vertexBuffer: MTLBuffer
    let uniformBuffer: MTLBuffer
    let vertexCount: Int
    
    init(pipeline: MTLRenderPipelineState, vertexBuffer: MTLBuffer, uniformBuffer: MTLBuffer, vertexCount: Int) {
        self.pipeline = pipeline
        self.vertexBuffer = vertexBuffer
        self.uniformBuffer = uniformBuffer
        self.vertexCount = vertexCount
    }
    
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        // Handle size changes
    }
    
    func draw(in view: MTKView) {
        guard let commandBuffer = view.device?.makeCommandQueue()?.makeCommandBuffer(),
              let renderPassDescriptor = view.currentRenderPassDescriptor,
              let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor) else {
            return
        }
        
        renderEncoder.setRenderPipelineState(pipeline)
        renderEncoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
        renderEncoder.setVertexBuffer(uniformBuffer, offset: 0, index: 1)
        renderEncoder.drawPrimitives(type: .lineStrip, vertexStart: 0, vertexCount: vertexCount)
        renderEncoder.endEncoding()
        
        if let drawable = view.currentDrawable {
            commandBuffer.present(drawable)
        }
        
        commandBuffer.commit()
    }
}

class BarChartRenderer: NSObject, MTKViewDelegate {
    let pipeline: MTLRenderPipelineState
    let vertexBuffer: MTLBuffer
    let uniformBuffer: MTLBuffer
    let vertexCount: Int
    
    init(pipeline: MTLRenderPipelineState, vertexBuffer: MTLBuffer, uniformBuffer: MTLBuffer, vertexCount: Int) {
        self.pipeline = pipeline
        self.vertexBuffer = vertexBuffer
        self.uniformBuffer = uniformBuffer
        self.vertexCount = vertexCount
    }
    
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        // Handle size changes
    }
    
    func draw(in view: MTKView) {
        guard let commandBuffer = view.device?.makeCommandQueue()?.makeCommandBuffer(),
              let renderPassDescriptor = view.currentRenderPassDescriptor,
              let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor) else {
            return
        }
        
        renderEncoder.setRenderPipelineState(pipeline)
        renderEncoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
        renderEncoder.setVertexBuffer(uniformBuffer, offset: 0, index: 1)
        renderEncoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: vertexCount)
        renderEncoder.endEncoding()
        
        if let drawable = view.currentDrawable {
            commandBuffer.present(drawable)
        }
        
        commandBuffer.commit()
    }
}

class AreaChartRenderer: NSObject, MTKViewDelegate {
    let pipeline: MTLRenderPipelineState
    let vertexBuffer: MTLBuffer
    let uniformBuffer: MTLBuffer
    let vertexCount: Int
    
    init(pipeline: MTLRenderPipelineState, vertexBuffer: MTLBuffer, uniformBuffer: MTLBuffer, vertexCount: Int) {
        self.pipeline = pipeline
        self.vertexBuffer = vertexBuffer
        self.uniformBuffer = uniformBuffer
        self.vertexCount = vertexCount
    }
    
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        // Handle size changes
    }
    
    func draw(in view: MTKView) {
        guard let commandBuffer = view.device?.makeCommandQueue()?.makeCommandBuffer(),
              let renderPassDescriptor = view.currentRenderPassDescriptor,
              let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor) else {
            return
        }
        
        renderEncoder.setRenderPipelineState(pipeline)
        renderEncoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
        renderEncoder.setVertexBuffer(uniformBuffer, offset: 0, index: 1)
        renderEncoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: vertexCount)
        renderEncoder.endEncoding()
        
        if let drawable = view.currentDrawable {
            commandBuffer.present(drawable)
        }
        
        commandBuffer.commit()
    }
}

class RealTimeChartRenderer: NSObject, MTKViewDelegate {
    let pipeline: MTLRenderPipelineState
    let vertexBuffer: MTLBuffer
    let uniformBuffer: MTLBuffer
    let vertexCount: Int
    let device: MTLDevice
    
    init(pipeline: MTLRenderPipelineState, vertexBuffer: MTLBuffer, uniformBuffer: MTLBuffer, vertexCount: Int, device: MTLDevice) {
        self.pipeline = pipeline
        self.vertexBuffer = vertexBuffer
        self.uniformBuffer = uniformBuffer
        self.vertexCount = vertexCount
        self.device = device
    }
    
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        // Handle size changes
    }
    
    func draw(in view: MTKView) {
        guard let commandBuffer = device.makeCommandQueue()?.makeCommandBuffer(),
              let renderPassDescriptor = view.currentRenderPassDescriptor,
              let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor) else {
            return
        }
        
        // Clear background
        renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 0.1)
        
        renderEncoder.setRenderPipelineState(pipeline)
        renderEncoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
        renderEncoder.setVertexBuffer(uniformBuffer, offset: 0, index: 1)
        renderEncoder.drawPrimitives(type: .lineStrip, vertexStart: 0, vertexCount: vertexCount)
        renderEncoder.endEncoding()
        
        if let drawable = view.currentDrawable {
            commandBuffer.present(drawable)
        }
        
        commandBuffer.commit()
    }
}