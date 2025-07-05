import SwiftUI
import RealityKit
import ARKit

/// SwiftUI view wrapper for AR health visualizer
public struct ARHealthVisualizerView: UIViewRepresentable {
    @ObservedObject private var visualizer = ARHealthVisualizer.shared
    @State private var selectedVisualization: ARVisualizationType = .heartRate
    @State private var showingControls = true
    
    public init() {}
    
    public func makeUIView(context: Context) -> ARView {
        let arView = ARView(frame: .zero, cameraMode: .ar, automaticallyConfigureSession: false)
        
        // Set up AR view
        arView.session.delegate = visualizer
        arView.environment.sceneUnderstanding.options = [.occlusion, .physics]
        
        // Add gesture recognizers
        let tapGesture = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleTap(_:)))
        arView.addGestureRecognizer(tapGesture)
        
        let pinchGesture = UIPinchGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handlePinch(_:)))
        arView.addGestureRecognizer(pinchGesture)
        
        return arView
    }
    
    public func updateUIView(_ uiView: ARView, context: Context) {
        // Update AR view if needed
    }
    
    public func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    public class Coordinator: NSObject {
        var parent: ARHealthVisualizerView
        
        init(_ parent: ARHealthVisualizerView) {
            self.parent = parent
        }
        
        @objc func handleTap(_ gesture: UITapGestureRecognizer) {
            let location = gesture.location(in: gesture.view)
            
            // Perform raycast to find where user tapped in 3D space
            guard let arView = gesture.view as? ARView else { return }
            
            let results = arView.raycast(from: location, allowing: .estimatedPlane, alignment: .any)
            
            if let firstResult = results.first {
                let position = firstResult.worldTransform.columns.3
                let worldPosition = SIMD3<Float>(position.x, position.y, position.z)
                
                // Start visualization at tapped location
                Task {
                    await parent.visualizer.startVisualization(
                        type: parent.selectedVisualization,
                        healthData: parent.visualizer.healthData ?? HealthData(),
                        position: worldPosition
                    )
                }
            }
        }
        
        @objc func handlePinch(_ gesture: UIPinchGestureRecognizer) {
            let scale = Float(gesture.scale)
            parent.visualizer.setScale(scale)
        }
    }
}

/// Main AR Health Visualizer View with controls
public struct ARHealthVisualizerMainView: View {
    @StateObject private var visualizer = ARHealthVisualizer.shared
    @State private var selectedVisualization: ARVisualizationType = .heartRate
    @State private var showingControls = true
    @State private var isARSessionActive = false
    
    public init() {}
    
    public var body: some View {
        ZStack {
            // AR View
            ARHealthVisualizerView()
                .edgesIgnoringSafeArea(.all)
            
            // Overlay controls
            if showingControls {
                VStack {
                    // Top controls
                    topControls
                    
                    Spacer()
                    
                    // Bottom controls
                    bottomControls
                }
                .padding()
            }
            
            // Loading indicator
            if visualizer.predictionInProgress {
                loadingView
            }
        }
        .onAppear {
            initializeARSession()
        }
        .onDisappear {
            visualizer.stopARSession()
        }
    }
    
    private var topControls: some View {
        HStack {
            // Back button
            Button(action: {
                // Navigate back
            }) {
                Image(systemName: "chevron.left")
                    .font(.title2)
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.black.opacity(0.5))
                    .clipShape(Circle())
            }
            
            Spacer()
            
            // Visualization type selector
            Picker("Visualization", selection: $selectedVisualization) {
                ForEach(ARVisualizationType.allCases, id: \.self) { type in
                    Text(type.rawValue).tag(type)
                }
            }
            .pickerStyle(MenuPickerStyle())
            .padding()
            .background(Color.black.opacity(0.5))
            .cornerRadius(10)
            
            Spacer()
            
            // Settings button
            Button(action: {
                showingControls.toggle()
            }) {
                Image(systemName: "gear")
                    .font(.title2)
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.black.opacity(0.5))
                    .clipShape(Circle())
            }
        }
    }
    
    private var bottomControls: some View {
        VStack(spacing: 20) {
            // Health data display
            if let healthData = visualizer.healthData {
                healthDataCard(data: healthData)
            }
            
            // Control buttons
            HStack(spacing: 20) {
                // Start visualization button
                Button(action: {
                    startVisualization()
                }) {
                    HStack {
                        Image(systemName: "play.fill")
                        Text("Start")
                    }
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(10)
                }
                
                // Scale controls
                VStack {
                    Button(action: {
                        visualizer.setScale(visualizer.visualizationScale + 0.1)
                    }) {
                        Image(systemName: "plus")
                            .foregroundColor(.white)
                            .padding(8)
                            .background(Color.black.opacity(0.5))
                            .clipShape(Circle())
                    }
                    
                    Button(action: {
                        visualizer.setScale(max(0.1, visualizer.visualizationScale - 0.1))
                    }) {
                        Image(systemName: "minus")
                            .foregroundColor(.white)
                            .padding(8)
                            .background(Color.black.opacity(0.5))
                            .clipShape(Circle())
                    }
                }
                
                // Interactivity toggle
                Button(action: {
                    visualizer.toggleInteractivity()
                }) {
                    Image(systemName: visualizer.isInteractive ? "hand.tap.fill" : "hand.tap")
                        .foregroundColor(.white)
                        .padding()
                        .background(visualizer.isInteractive ? Color.green : Color.gray)
                        .clipShape(Circle())
                }
            }
        }
        .padding()
        .background(Color.black.opacity(0.3))
        .cornerRadius(15)
    }
    
    private func healthDataCard(data: HealthData) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Current Health Data")
                .font(.headline)
                .foregroundColor(.white)
            
            HStack {
                VStack(alignment: .leading) {
                    if let heartRate = data.heartRate {
                        Text("Heart Rate: \(Int(heartRate)) BPM")
                            .foregroundColor(.white)
                    }
                    if let stressLevel = data.stressLevel {
                        Text("Stress: \(Int(stressLevel * 100))%")
                            .foregroundColor(.white)
                    }
                }
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    if let activityLevel = data.activityLevel {
                        Text("Activity: \(Int(activityLevel * 100))%")
                            .foregroundColor(.white)
                    }
                    if let sleepScore = data.sleepScore {
                        Text("Sleep Score: \(Int(sleepScore))")
                            .foregroundColor(.white)
                    }
                }
            }
        }
        .padding()
        .background(Color.black.opacity(0.5))
        .cornerRadius(10)
    }
    
    private var loadingView: some View {
        VStack {
            ProgressView()
                .scaleEffect(1.5)
                .progressViewStyle(CircularProgressViewStyle(tint: .white))
            
            Text("Loading AR Visualization...")
                .foregroundColor(.white)
                .padding(.top)
        }
        .padding()
        .background(Color.black.opacity(0.7))
        .cornerRadius(15)
    }
    
    // MARK: - Private Methods
    
    private func initializeARSession() {
        Task {
            isARSessionActive = await visualizer.initializeARSession()
        }
    }
    
    private func startVisualization() {
        guard let healthData = visualizer.healthData else {
            // Use sample data if no real data available
            let sampleData = HealthData()
            visualizer.healthData = sampleData
            
            Task {
                await visualizer.startVisualization(
                    type: selectedVisualization,
                    healthData: sampleData
                )
            }
            return
        }
        
        Task {
            await visualizer.startVisualization(
                type: selectedVisualization,
                healthData: healthData
            )
        }
    }
}

/// AR Visualization Settings View
public struct ARVisualizationSettingsView: View {
    @ObservedObject private var visualizer = ARHealthVisualizer.shared
    @Environment(\.dismiss) private var dismiss
    
    @State private var visualizationScale: Float = 1.0
    @State private var isInteractive = true
    @State private var showHealthData = true
    @State private var autoUpdate = true
    
    public init() {}
    
    public var body: some View {
        NavigationView {
            Form {
                Section("Visualization") {
                    VStack(alignment: .leading) {
                        Text("Scale: \(String(format: "%.1f", visualizationScale))")
                        Slider(value: $visualizationScale, in: 0.1...3.0) { _ in
                            visualizer.setScale(visualizationScale)
                        }
                    }
                    
                    Toggle("Interactive Mode", isOn: $isInteractive)
                        .onChange(of: isInteractive) { _ in
                            visualizer.toggleInteractivity()
                        }
                }
                
                Section("Display") {
                    Toggle("Show Health Data", isOn: $showHealthData)
                    Toggle("Auto Update", isOn: $autoUpdate)
                }
                
                Section("AR Session") {
                    HStack {
                        Text("Session Status")
                        Spacer()
                        Text(visualizer.isSessionActive ? "Active" : "Inactive")
                            .foregroundColor(visualizer.isSessionActive ? .green : .red)
                    }
                    
                    Button("Restart AR Session") {
                        Task {
                            await visualizer.initializeARSession()
                        }
                    }
                    .foregroundColor(.blue)
                }
                
                Section("About") {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("AR Health Visualizer")
                            .font(.headline)
                        Text("Version 1.0.0")
                            .foregroundColor(.secondary)
                        Text("Display your health data in augmented reality with interactive 3D visualizations.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("AR Settings")
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
}

/// Preview for AR Health Visualizer
struct ARHealthVisualizerView_Previews: PreviewProvider {
    static var previews: some View {
        ARHealthVisualizerMainView()
    }
} 