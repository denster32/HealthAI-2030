import SwiftUI
import Metal
import MetalKit
import RealityKit
import simd

@available(tvOS 18.0, *)
class AdaptiveFractalRenderer: NSObject, ObservableObject {
    
    // MARK: - Properties
    
    @Published var isRendering = false
    @Published var currentFractalType: FractalType = .mandelbrot
    @Published var biometricIntensity: Float = 0.5
    @Published var colorScheme: FractalColorScheme = .health
    
    private var device: MTLDevice
    private var commandQueue: MTLCommandQueue
    private var computePipeline: MTLComputePipelineState?
    private var renderPipelineState: MTLRenderPipelineState?
    
    // Biometric data integration
    private var heartRateData: [Float] = []
    private var hrvData: [Float] = []
    private var breathingData: [Float] = []
    
    // Fractal parameters
    private var fractalParameters = FractalParameters()
    
    // MARK: - Initialization
    
    override init() {
        guard let device = MTLCreateSystemDefaultDevice() else {
            fatalError("Metal is not supported on this device")
        }
        
        self.device = device
        self.commandQueue = device.makeCommandQueue()!
        
        super.init()
        
        setupMetalPipeline()
        setupRealityKitIntegration()
    }
    
    // MARK: - Metal Setup
    
    private func setupMetalPipeline() {
        guard let library = device.makeDefaultLibrary() else {
            print("Failed to create Metal library")
            return
        }
        
        // Setup compute pipeline for fractal generation
        guard let computeFunction = library.makeFunction(name: "generateFractal") else {
            print("Failed to create compute function")
            return
        }
        
        do {
            computePipeline = try device.makeComputePipelineState(function: computeFunction)
        } catch {
            print("Failed to create compute pipeline: \(error)")
        }
        
        // Setup render pipeline for display
        let renderPipelineDescriptor = MTLRenderPipelineDescriptor()
        renderPipelineDescriptor.vertexFunction = library.makeFunction(name: "vertexShader")
        renderPipelineDescriptor.fragmentFunction = library.makeFunction(name: "fragmentShader")
        renderPipelineDescriptor.colorAttachments[0].pixelFormat = .bgra8Unorm
        
        do {
            renderPipelineState = try device.makeRenderPipelineState(descriptor: renderPipelineDescriptor)
        } catch {
            print("Failed to create render pipeline: \(error)")
        }
    }
    
    private func setupRealityKitIntegration() {
        // Configure RealityKit integration for 3D fractal visualization
    }
    
    // MARK: - Biometric Data Integration
    
    func updateBiometricData(heartRate: Float, hrv: Float, breathing: Float) {
        heartRateData.append(heartRate)
        hrvData.append(hrv)
        breathingData.append(breathing)
        
        // Keep only recent data points
        if heartRateData.count > 100 {
            heartRateData.removeFirst()
            hrvData.removeFirst()
            breathingData.removeFirst()
        }
        
        updateFractalParameters()
    }
    
    private func updateFractalParameters() {
        guard !heartRateData.isEmpty else { return }
        
        // Calculate biometric-based parameters
        let avgHeartRate = heartRateData.reduce(0, +) / Float(heartRateData.count)
        let avgHRV = hrvData.reduce(0, +) / Float(hrvData.count)
        let avgBreathing = breathingData.reduce(0, +) / Float(breathingData.count)
        
        // Normalize values
        let normalizedHeartRate = normalize(avgHeartRate, min: 60, max: 100)
        let normalizedHRV = normalize(avgHRV, min: 20, max: 80)
        let normalizedBreathing = normalize(avgBreathing, min: 12, max: 20)
        
        // Update fractal parameters based on biometrics
        fractalParameters.zoom = 1.0 + (normalizedHeartRate * 3.0)
        fractalParameters.iterations = Int(50 + (normalizedHRV * 100))
        fractalParameters.colorShift = normalizedBreathing * 360.0
        fractalParameters.morphingSpeed = 0.5 + (normalizedHeartRate * 1.5)
        
        // Update biometric intensity for UI
        biometricIntensity = (normalizedHeartRate + normalizedHRV + normalizedBreathing) / 3.0
    }
    
    private func normalize(_ value: Float, min: Float, max: Float) -> Float {
        return simd_clamp((value - min) / (max - min), 0.0, 1.0)
    }
    
    // MARK: - Fractal Generation
    
    func generateFractal(size: CGSize) -> MTLTexture? {
        guard let computePipeline = computePipeline,
              let commandBuffer = commandQueue.makeCommandBuffer(),
              let encoder = commandBuffer.makeComputeCommandEncoder() else {
            return nil
        }
        
        // Create output texture
        let textureDescriptor = MTLTextureDescriptor.texture2DDescriptor(
            pixelFormat: .bgra8Unorm,
            width: Int(size.width),
            height: Int(size.height),
            mipmapped: false
        )
        textureDescriptor.usage = [.shaderWrite, .shaderRead]
        
        guard let outputTexture = device.makeTexture(descriptor: textureDescriptor) else {
            return nil
        }
        
        encoder.setComputePipelineState(computePipeline)
        encoder.setTexture(outputTexture, index: 0)
        encoder.setBytes(&fractalParameters, length: MemoryLayout<FractalParameters>.size, index: 0)
        
        let threadgroupSize = MTLSize(width: 16, height: 16, depth: 1)
        let threadgroups = MTLSize(
            width: (Int(size.width) + threadgroupSize.width - 1) / threadgroupSize.width,
            height: (Int(size.height) + threadgroupSize.height - 1) / threadgroupSize.height,
            depth: 1
        )
        
        encoder.dispatchThreadgroups(threadgroups, threadsPerThreadgroup: threadgroupSize)
        encoder.endEncoding()
        
        commandBuffer.commit()
        commandBuffer.waitUntilCompleted()
        
        return outputTexture
    }
    
    // MARK: - Animation
    
    func startAnimation() {
        isRendering = true
        animateParameters()
    }
    
    func stopAnimation() {
        isRendering = false
    }
    
    private func animateParameters() {
        guard isRendering else { return }
        
        let currentTime = CACurrentMediaTime()
        
        // Animate fractal parameters based on time and biometrics
        fractalParameters.timeOffset = Float(currentTime) * fractalParameters.morphingSpeed
        fractalParameters.centerX += sin(Float(currentTime) * 0.1) * 0.001
        fractalParameters.centerY += cos(Float(currentTime) * 0.1) * 0.001
        
        // Schedule next animation frame
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0/60.0) {
            self.animateParameters()
        }
    }
    
    // MARK: - Color Scheme Management
    
    func updateColorScheme(_ scheme: FractalColorScheme) {
        colorScheme = scheme
        fractalParameters.colorMode = scheme.rawValue
    }
    
    // MARK: - Fractal Type Management
    
    func setFractalType(_ type: FractalType) {
        currentFractalType = type
        fractalParameters.fractalType = type.rawValue
    }
}

// MARK: - Supporting Types

struct FractalParameters {
    var fractalType: Int32 = 0
    var zoom: Float = 1.0
    var centerX: Float = 0.0
    var centerY: Float = 0.0
    var iterations: Int32 = 100
    var colorShift: Float = 0.0
    var colorMode: Int32 = 0
    var morphingSpeed: Float = 1.0
    var timeOffset: Float = 0.0
    var biometricInfluence: Float = 0.5
}

enum FractalType: Int32, CaseIterable {
    case mandelbrot = 0
    case julia = 1
    case burningShip = 2
    case newton = 3
    case tricorn = 4
    
    var displayName: String {
        switch self {
        case .mandelbrot: return "Mandelbrot"
        case .julia: return "Julia"
        case .burningShip: return "Burning Ship"
        case .newton: return "Newton"
        case .tricorn: return "Tricorn"
        }
    }
}

enum FractalColorScheme: Int32, CaseIterable {
    case health = 0
    case rainbow = 1
    case ocean = 2
    case sunset = 3
    case forest = 4
    case cosmic = 5
    
    var displayName: String {
        switch self {
        case .health: return "Health"
        case .rainbow: return "Rainbow"
        case .ocean: return "Ocean"
        case .sunset: return "Sunset"
        case .forest: return "Forest"
        case .cosmic: return "Cosmic"
        }
    }
    
    var colors: [Color] {
        switch self {
        case .health:
            return [.green, .blue, .red, .yellow]
        case .rainbow:
            return [.red, .orange, .yellow, .green, .blue, .purple]
        case .ocean:
            return [.blue, .cyan, .white, .blue]
        case .sunset:
            return [.orange, .red, .pink, .purple]
        case .forest:
            return [.green, .yellow, .brown, .green]
        case .cosmic:
            return [.purple, .blue, .black, .white]
        }
    }
}

@available(tvOS 18.0, *)
struct AdaptiveFractalView: View {
    @StateObject private var renderer = AdaptiveFractalRenderer()
    @State private var selectedFractalType: FractalType = .mandelbrot
    @State private var selectedColorScheme: FractalColorScheme = .health
    @State private var showControls = false
    
    var body: some View {
        ZStack {
            // Fractal visualization
            FractalMetalView(renderer: renderer)
                .ignoresSafeArea()
            
            // Overlay controls
            if showControls {
                VStack {
                    Spacer()
                    
                    FractalControlsView(
                        selectedFractalType: $selectedFractalType,
                        selectedColorScheme: $selectedColorScheme,
                        renderer: renderer
                    )
                    .background(Color.black.opacity(0.7))
                    .cornerRadius(20)
                    .padding()
                }
                .transition(.move(edge: .bottom))
            }
            
            // Biometric intensity indicator
            VStack {
                HStack {
                    Spacer()
                    
                    BiometricIntensityIndicator(intensity: renderer.biometricIntensity)
                        .padding()
                }
                
                Spacer()
            }
        }
        .onTapGesture {
            withAnimation(.easeInOut(duration: 0.3)) {
                showControls.toggle()
            }
        }
        .onAppear {
            renderer.startAnimation()
        }
        .onDisappear {
            renderer.stopAnimation()
        }
        .onChange(of: selectedFractalType) { newType in
            renderer.setFractalType(newType)
        }
        .onChange(of: selectedColorScheme) { newScheme in
            renderer.updateColorScheme(newScheme)
        }
    }
}

struct FractalMetalView: UIViewRepresentable {
    let renderer: AdaptiveFractalRenderer
    
    func makeUIView(context: Context) -> MTKView {
        let mtkView = MTKView()
        mtkView.device = MTLCreateSystemDefaultDevice()
        mtkView.delegate = context.coordinator
        mtkView.preferredFramesPerSecond = 60
        mtkView.enableSetNeedsDisplay = true
        return mtkView
    }
    
    func updateUIView(_ uiView: MTKView, context: Context) {
        // Update view if needed
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, MTKViewDelegate {
        var parent: FractalMetalView
        
        init(_ parent: FractalMetalView) {
            self.parent = parent
        }
        
        func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
            // Handle size changes
        }
        
        func draw(in view: MTKView) {
            guard let drawable = view.currentDrawable else { return }
            
            // Generate and display fractal
            if let fractalTexture = parent.renderer.generateFractal(size: view.drawableSize) {
                // Render the fractal texture to the drawable
                renderFractal(texture: fractalTexture, to: drawable)
            }
        }
        
        private func renderFractal(texture: MTLTexture, to drawable: CAMetalDrawable) {
            // Implementation for rendering fractal texture to drawable
        }
    }
}

struct FractalControlsView: View {
    @Binding var selectedFractalType: FractalType
    @Binding var selectedColorScheme: FractalColorScheme
    let renderer: AdaptiveFractalRenderer
    
    var body: some View {
        VStack(spacing: 20) {
            // Fractal Type Selector
            VStack(alignment: .leading, spacing: 10) {
                Text("Fractal Type")
                    .font(.headline)
                    .foregroundColor(.white)
                
                Picker("Fractal Type", selection: $selectedFractalType) {
                    ForEach(FractalType.allCases, id: \.self) { type in
                        Text(type.displayName).tag(type)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
            }
            
            // Color Scheme Selector
            VStack(alignment: .leading, spacing: 10) {
                Text("Color Scheme")
                    .font(.headline)
                    .foregroundColor(.white)
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 15) {
                        ForEach(FractalColorScheme.allCases, id: \.self) { scheme in
                            ColorSchemeButton(
                                scheme: scheme,
                                isSelected: selectedColorScheme == scheme
                            ) {
                                selectedColorScheme = scheme
                            }
                        }
                    }
                    .padding(.horizontal)
                }
            }
            
            // Biometric Influence Indicator
            VStack(alignment: .leading, spacing: 10) {
                Text("Biometric Influence")
                    .font(.headline)
                    .foregroundColor(.white)
                
                HStack {
                    Text("Heart Rate")
                        .font(.caption)
                        .foregroundColor(.red)
                    
                    Text("HRV")
                        .font(.caption)
                        .foregroundColor(.green)
                    
                    Text("Breathing")
                        .font(.caption)
                        .foregroundColor(.blue)
                    
                    Spacer()
                    
                    Text("Intensity: \(Int(renderer.biometricIntensity * 100))%")
                        .font(.caption)
                        .foregroundColor(.white)
                }
            }
        }
        .padding()
    }
}

struct ColorSchemeButton: View {
    let scheme: FractalColorScheme
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 8) {
                LinearGradient(
                    gradient: Gradient(colors: scheme.colors),
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .frame(width: 60, height: 30)
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.white, lineWidth: isSelected ? 3 : 1)
                )
                
                Text(scheme.displayName)
                    .font(.caption)
                    .foregroundColor(.white)
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct BiometricIntensityIndicator: View {
    let intensity: Float
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: "waveform.path.ecg")
                .font(.title2)
                .foregroundColor(intensityColor)
            
            Text("\(Int(intensity * 100))%")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.white)
            
            RoundedRectangle(cornerRadius: 4)
                .fill(intensityColor)
                .frame(width: 4, height: 40 * CGFloat(intensity))
                .animation(.easeInOut(duration: 0.3), value: intensity)
        }
        .padding(12)
        .background(Color.black.opacity(0.7))
        .cornerRadius(12)
    }
    
    private var intensityColor: Color {
        if intensity > 0.8 {
            return .red
        } else if intensity > 0.6 {
            return .orange
        } else if intensity > 0.4 {
            return .yellow
        } else {
            return .green
        }
    }
}

#Preview {
    AdaptiveFractalView()
}