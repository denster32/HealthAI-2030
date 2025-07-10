import SwiftUI
import SceneKit

// MARK: - 3D Health Visualizations
/// Comprehensive 3D health data visualization components for HealthAI 2030
/// Provides 3D visualizations for health data analysis and education
public struct ThreeDHealthVisualizations {
    
    // MARK: - 3D Heart Visualization
    
    /// 3D heart model with health data overlay
    public struct Heart3DVisualization: View {
        let heartRate: Double
        let bloodPressure: BloodPressureData?
        let ecgData: [Double]?
        @State private var rotation: Double = 0
        @State private var isAnimating: Bool = false
        
        public init(
            heartRate: Double,
            bloodPressure: BloodPressureData? = nil,
            ecgData: [Double]? = nil
        ) {
            self.heartRate = heartRate
            self.bloodPressure = bloodPressure
            self.ecgData = ecgData
        }
        
        public var body: some View {
            VStack(spacing: 20) {
                // 3D Heart Scene
                ZStack {
                    SceneView(
                        scene: createHeartScene(),
                        pointOfView: createHeartCamera(),
                        options: [.allowsCameraControl, .autoenablesDefaultLighting]
                    )
                    .frame(height: 300)
                    .cornerRadius(16)
                    .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 5)
                    
                    // Health data overlay
                    VStack {
                        HStack {
                            VStack(alignment: .leading) {
                                Text("Heart Rate")
                                    .font(.caption)
                                    .foregroundColor(.white)
                                Text("\(Int(heartRate)) BPM")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.red)
                            }
                            .padding()
                            .background(Color.black.opacity(0.7))
                            .cornerRadius(8)
                            
                            Spacer()
                        }
                        Spacer()
                    }
                    .padding()
                }
                
                // Controls
                HStack(spacing: 20) {
                    Button(action: { isAnimating.toggle() }) {
                        HStack(spacing: 8) {
                            Image(systemName: isAnimating ? "pause.fill" : "play.fill")
                            Text(isAnimating ? "Pause" : "Animate")
                        }
                        .font(.subheadline)
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.blue)
                        .cornerRadius(8)
                    }
                    
                    Button(action: { rotation += 90 }) {
                        HStack(spacing: 8) {
                            Image(systemName: "rotate.3d")
                            Text("Rotate")
                        }
                        .font(.subheadline)
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.green)
                        .cornerRadius(8)
                    }
                }
            }
            .onAppear {
                startHeartbeatAnimation()
            }
        }
        
        private func createHeartScene() -> SCNScene {
            let scene = SCNScene()
            
            // Create heart geometry
            let heartGeometry = createHeartGeometry()
            let heartNode = SCNNode(geometry: heartGeometry)
            heartNode.geometry?.firstMaterial?.diffuse.contents = UIColor.red
            heartNode.geometry?.firstMaterial?.specular.contents = UIColor.white
            heartNode.geometry?.firstMaterial?.shininess = 0.8
            
            // Add heartbeat animation
            if isAnimating {
                let scaleAction = SCNAction.scale(to: 1.1, duration: 0.5)
                let scaleBackAction = SCNAction.scale(to: 1.0, duration: 0.5)
                let sequence = SCNAction.sequence([scaleAction, scaleBackAction])
                heartNode.runAction(SCNAction.repeatForever(sequence))
            }
            
            scene.rootNode.addChildNode(heartNode)
            return scene
        }
        
        private func createHeartGeometry() -> SCNGeometry {
            // Create a simplified heart shape using custom geometry
            let heartShape = UIBezierPath()
            heartShape.move(to: CGPoint(x: 0, y: 0.5))
            heartShape.addCurve(to: CGPoint(x: -0.5, y: -0.5), controlPoint1: CGPoint(x: -0.3, y: 0.3), controlPoint2: CGPoint(x: -0.5, y: 0))
            heartShape.addCurve(to: CGPoint(x: 0, y: -0.8), controlPoint1: CGPoint(x: -0.5, y: -0.8), controlPoint2: CGPoint(x: -0.3, y: -0.8))
            heartShape.addCurve(to: CGPoint(x: 0.5, y: -0.5), controlPoint1: CGPoint(x: 0.3, y: -0.8), controlPoint2: CGPoint(x: 0.5, y: -0.8))
            heartShape.addCurve(to: CGPoint(x: 0, y: 0.5), controlPoint1: CGPoint(x: 0.5, y: 0), controlPoint2: CGPoint(x: 0.3, y: 0.3))
            heartShape.close()
            
            return SCNShape(path: heartShape, extrusionDepth: 0.2)
        }
        
        private func createHeartCamera() -> SCNNode {
            let camera = SCNCamera()
            camera.fieldOfView = 60
            let cameraNode = SCNNode()
            cameraNode.camera = camera
            cameraNode.position = SCNVector3(0, 0, 3)
            return cameraNode
        }
        
        private func startHeartbeatAnimation() {
            // Start the heartbeat animation
            isAnimating = true
        }
    }
    
    // MARK: - 3D Brain Visualization
    
    /// 3D brain model with activity visualization
    public struct Brain3DVisualization: View {
        let brainActivity: [BrainRegion: Double]
        let mood: String?
        @State private var isRotating: Bool = false
        
        public init(
            brainActivity: [BrainRegion: Double],
            mood: String? = nil
        ) {
            self.brainActivity = brainActivity
            self.mood = mood
        }
        
        public var body: some View {
            VStack(spacing: 20) {
                // 3D Brain Scene
                ZStack {
                    SceneView(
                        scene: createBrainScene(),
                        pointOfView: createBrainCamera(),
                        options: [.allowsCameraControl, .autoenablesDefaultLighting]
                    )
                    .frame(height: 300)
                    .cornerRadius(16)
                    .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 5)
                    
                    // Activity overlay
                    VStack {
                        HStack {
                            VStack(alignment: .leading) {
                                Text("Brain Activity")
                                    .font(.caption)
                                    .foregroundColor(.white)
                                if let mood = mood {
                                    Text(mood)
                                        .font(.title2)
                                        .fontWeight(.bold)
                                        .foregroundColor(.blue)
                                }
                            }
                            .padding()
                            .background(Color.black.opacity(0.7))
                            .cornerRadius(8)
                            
                            Spacer()
                        }
                        Spacer()
                    }
                    .padding()
                }
                
                // Brain regions legend
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 16) {
                        ForEach(Array(brainActivity.keys), id: \.self) { region in
                            VStack(spacing: 4) {
                                Circle()
                                    .fill(region.color)
                                    .frame(width: 12, height: 12)
                                Text(region.name)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
        
        private func createBrainScene() -> SCNScene {
            let scene = SCNScene()
            
            // Create brain geometry
            let brainGeometry = createBrainGeometry()
            let brainNode = SCNNode(geometry: brainGeometry)
            brainNode.geometry?.firstMaterial?.diffuse.contents = UIColor.systemGray
            brainNode.geometry?.firstMaterial?.specular.contents = UIColor.white
            brainNode.geometry?.firstMaterial?.shininess = 0.6
            
            // Add rotation animation
            if isRotating {
                let rotationAction = SCNAction.rotateBy(x: 0, y: 2 * .pi, z: 0, duration: 10)
                brainNode.runAction(SCNAction.repeatForever(rotationAction))
            }
            
            scene.rootNode.addChildNode(brainNode)
            return scene
        }
        
        private func createBrainGeometry() -> SCNGeometry {
            // Create a simplified brain shape
            let brainShape = UIBezierPath()
            brainShape.move(to: CGPoint(x: 0, y: 0.8))
            brainShape.addCurve(to: CGPoint(x: -0.8, y: 0), controlPoint1: CGPoint(x: -0.4, y: 0.6), controlPoint2: CGPoint(x: -0.8, y: 0.3))
            brainShape.addCurve(to: CGPoint(x: 0, y: -0.8), controlPoint1: CGPoint(x: -0.8, y: -0.3), controlPoint2: CGPoint(x: -0.4, y: -0.6))
            brainShape.addCurve(to: CGPoint(x: 0.8, y: 0), controlPoint1: CGPoint(x: 0.4, y: -0.6), controlPoint2: CGPoint(x: 0.8, y: -0.3))
            brainShape.addCurve(to: CGPoint(x: 0, y: 0.8), controlPoint1: CGPoint(x: 0.8, y: 0.3), controlPoint2: CGPoint(x: 0.4, y: 0.6))
            brainShape.close()
            
            return SCNShape(path: brainShape, extrusionDepth: 0.3)
        }
        
        private func createBrainCamera() -> SCNNode {
            let camera = SCNCamera()
            camera.fieldOfView = 60
            let cameraNode = SCNNode()
            cameraNode.camera = camera
            cameraNode.position = SCNVector3(0, 0, 3)
            return cameraNode
        }
    }
    
    // MARK: - 3D Body Visualization
    
    /// 3D body model with health metrics overlay
    public struct Body3DVisualization: View {
        let bodyMetrics: BodyMetrics
        let selectedRegion: BodyRegion?
        @State private var isRotating: Bool = false
        
        public init(
            bodyMetrics: BodyMetrics,
            selectedRegion: BodyRegion? = nil
        ) {
            self.bodyMetrics = bodyMetrics
            self.selectedRegion = selectedRegion
        }
        
        public var body: some View {
            VStack(spacing: 20) {
                // 3D Body Scene
                ZStack {
                    SceneView(
                        scene: createBodyScene(),
                        pointOfView: createBodyCamera(),
                        options: [.allowsCameraControl, .autoenablesDefaultLighting]
                    )
                    .frame(height: 400)
                    .cornerRadius(16)
                    .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 5)
                    
                    // Metrics overlay
                    VStack {
                        HStack {
                            VStack(alignment: .leading) {
                                Text("Body Metrics")
                                    .font(.caption)
                                    .foregroundColor(.white)
                                Text("BMI: \(String(format: "%.1f", bodyMetrics.bmi))")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.green)
                            }
                            .padding()
                            .background(Color.black.opacity(0.7))
                            .cornerRadius(8)
                            
                            Spacer()
                        }
                        Spacer()
                    }
                    .padding()
                }
                
                // Body regions
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 16) {
                        ForEach(BodyRegion.allCases, id: \.self) { region in
                            Button(action: {}) {
                                VStack(spacing: 4) {
                                    Image(systemName: region.icon)
                                        .font(.title2)
                                        .foregroundColor(selectedRegion == region ? .blue : .secondary)
                                    Text(region.name)
                                        .font(.caption)
                                        .foregroundColor(selectedRegion == region ? .blue : .secondary)
                                }
                            }
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
        
        private func createBodyScene() -> SCNScene {
            let scene = SCNScene()
            
            // Create body geometry
            let bodyGeometry = createBodyGeometry()
            let bodyNode = SCNNode(geometry: bodyGeometry)
            bodyNode.geometry?.firstMaterial?.diffuse.contents = UIColor.systemBlue
            bodyNode.geometry?.firstMaterial?.specular.contents = UIColor.white
            bodyNode.geometry?.firstMaterial?.shininess = 0.5
            
            scene.rootNode.addChildNode(bodyNode)
            return scene
        }
        
        private func createBodyGeometry() -> SCNGeometry {
            // Create a simplified human body shape
            let bodyShape = UIBezierPath()
            bodyShape.move(to: CGPoint(x: 0, y: 1.0))
            bodyShape.addLine(to: CGPoint(x: -0.3, y: 0.8))
            bodyShape.addLine(to: CGPoint(x: -0.4, y: 0.4))
            bodyShape.addLine(to: CGPoint(x: -0.3, y: 0))
            bodyShape.addLine(to: CGPoint(x: -0.2, y: -0.4))
            bodyShape.addLine(to: CGPoint(x: 0, y: -0.6))
            bodyShape.addLine(to: CGPoint(x: 0.2, y: -0.4))
            bodyShape.addLine(to: CGPoint(x: 0.3, y: 0))
            bodyShape.addLine(to: CGPoint(x: 0.4, y: 0.4))
            bodyShape.addLine(to: CGPoint(x: 0.3, y: 0.8))
            bodyShape.close()
            
            return SCNShape(path: bodyShape, extrusionDepth: 0.2)
        }
        
        private func createBodyCamera() -> SCNNode {
            let camera = SCNCamera()
            camera.fieldOfView = 60
            let cameraNode = SCNNode()
            cameraNode.camera = camera
            cameraNode.position = SCNVector3(0, 0, 3)
            return cameraNode
        }
    }
    
    // MARK: - 3D Lung Visualization
    
    /// 3D lung model with respiratory data
    public struct Lung3DVisualization: View {
        let respiratoryRate: Double
        let oxygenSaturation: Double
        let lungCapacity: Double
        @State private var isBreathing: Bool = false
        
        public init(
            respiratoryRate: Double,
            oxygenSaturation: Double,
            lungCapacity: Double
        ) {
            self.respiratoryRate = respiratoryRate
            self.oxygenSaturation = oxygenSaturation
            self.lungCapacity = lungCapacity
        }
        
        public var body: some View {
            VStack(spacing: 20) {
                // 3D Lung Scene
                ZStack {
                    SceneView(
                        scene: createLungScene(),
                        pointOfView: createLungCamera(),
                        options: [.allowsCameraControl, .autoenablesDefaultLighting]
                    )
                    .frame(height: 300)
                    .cornerRadius(16)
                    .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 5)
                    
                    // Respiratory data overlay
                    VStack {
                        HStack {
                            VStack(alignment: .leading) {
                                Text("Respiratory Rate")
                                    .font(.caption)
                                    .foregroundColor(.white)
                                Text("\(Int(respiratoryRate)) BPM")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.blue)
                            }
                            .padding()
                            .background(Color.black.opacity(0.7))
                            .cornerRadius(8)
                            
                            Spacer()
                            
                            VStack(alignment: .trailing) {
                                Text("O₂ Saturation")
                                    .font(.caption)
                                    .foregroundColor(.white)
                                Text("\(Int(oxygenSaturation))%")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.green)
                            }
                            .padding()
                            .background(Color.black.opacity(0.7))
                            .cornerRadius(8)
                        }
                        Spacer()
                    }
                    .padding()
                }
                
                // Breathing animation control
                Button(action: { isBreathing.toggle() }) {
                    HStack(spacing: 8) {
                        Image(systemName: isBreathing ? "pause.fill" : "play.fill")
                        Text(isBreathing ? "Pause Breathing" : "Start Breathing")
                    }
                    .font(.subheadline)
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.blue)
                    .cornerRadius(8)
                }
            }
        }
        
        private func createLungScene() -> SCNScene {
            let scene = SCNScene()
            
            // Create left lung
            let leftLungGeometry = createLungGeometry()
            let leftLungNode = SCNNode(geometry: leftLungGeometry)
            leftLungNode.geometry?.firstMaterial?.diffuse.contents = UIColor.systemBlue
            leftLungNode.position = SCNVector3(-0.5, 0, 0)
            
            // Create right lung
            let rightLungGeometry = createLungGeometry()
            let rightLungNode = SCNNode(geometry: rightLungGeometry)
            rightLungNode.geometry?.firstMaterial?.diffuse.contents = UIColor.systemBlue
            rightLungNode.position = SCNVector3(0.5, 0, 0)
            
            // Add breathing animation
            if isBreathing {
                let scaleAction = SCNAction.scale(to: 1.2, duration: 2.0)
                let scaleBackAction = SCNAction.scale(to: 1.0, duration: 2.0)
                let sequence = SCNAction.sequence([scaleAction, scaleBackAction])
                leftLungNode.runAction(SCNAction.repeatForever(sequence))
                rightLungNode.runAction(SCNAction.repeatForever(sequence))
            }
            
            scene.rootNode.addChildNode(leftLungNode)
            scene.rootNode.addChildNode(rightLungNode)
            return scene
        }
        
        private func createLungGeometry() -> SCNGeometry {
            // Create a simplified lung shape
            let lungShape = UIBezierPath()
            lungShape.move(to: CGPoint(x: 0, y: 0.6))
            lungShape.addCurve(to: CGPoint(x: -0.3, y: 0), controlPoint1: CGPoint(x: -0.2, y: 0.4), controlPoint2: CGPoint(x: -0.3, y: 0.2))
            lungShape.addCurve(to: CGPoint(x: 0, y: -0.6), controlPoint1: CGPoint(x: -0.3, y: -0.2), controlPoint2: CGPoint(x: -0.2, y: -0.4))
            lungShape.addCurve(to: CGPoint(x: 0.3, y: 0), controlPoint1: CGPoint(x: 0.2, y: -0.4), controlPoint2: CGPoint(x: 0.3, y: -0.2))
            lungShape.addCurve(to: CGPoint(x: 0, y: 0.6), controlPoint1: CGPoint(x: 0.3, y: 0.2), controlPoint2: CGPoint(x: 0.2, y: 0.4))
            lungShape.close()
            
            return SCNShape(path: lungShape, extrusionDepth: 0.1)
        }
        
        private func createLungCamera() -> SCNNode {
            let camera = SCNCamera()
            camera.fieldOfView = 60
            let cameraNode = SCNNode()
            cameraNode.camera = camera
            cameraNode.position = SCNVector3(0, 0, 3)
            return cameraNode
        }
    }
}

// MARK: - Supporting Types

/// Brain region for activity visualization
public enum BrainRegion: String, CaseIterable {
    case frontal = "Frontal Lobe"
    case temporal = "Temporal Lobe"
    case parietal = "Parietal Lobe"
    case occipital = "Occipital Lobe"
    case cerebellum = "Cerebellum"
    case brainstem = "Brainstem"
    
    var name: String {
        return rawValue
    }
    
    var color: Color {
        switch self {
        case .frontal:
            return .red
        case .temporal:
            return .blue
        case .parietal:
            return .green
        case .occipital:
            return .orange
        case .cerebellum:
            return .purple
        case .brainstem:
            return .gray
        }
    }
}

/// Body region for visualization
public enum BodyRegion: String, CaseIterable {
    case head = "Head"
    case chest = "Chest"
    case abdomen = "Abdomen"
    case arms = "Arms"
    case legs = "Legs"
    
    var name: String {
        return rawValue
    }
    
    var icon: String {
        switch self {
        case .head:
            return "brain.head.profile"
        case .chest:
            return "heart.fill"
        case .abdomen:
            return "circle.fill"
        case .arms:
            return "figure.walk"
        case .legs:
            return "figure.walk"
        }
    }
}

/// Body metrics data
public struct BodyMetrics {
    let height: Double
    let weight: Double
    let bmi: Double
    let bodyFat: Double?
    let muscleMass: Double?
    
    public init(
        height: Double,
        weight: Double,
        bodyFat: Double? = nil,
        muscleMass: Double? = nil
    ) {
        self.height = height
        self.weight = weight
        self.bmi = weight / pow(height / 100, 2)
        self.bodyFat = bodyFat
        self.muscleMass = muscleMass
    }
}

/// Blood pressure data
public struct BloodPressureData {
    let systolic: Int
    let diastolic: Int
    
    public init(systolic: Int, diastolic: Int) {
        self.systolic = systolic
        self.diastolic = diastolic
    }
}

// MARK: - Extensions

public extension ThreeDHealthVisualizations {
    /// Create default brain activity data
    static func defaultBrainActivity() -> [BrainRegion: Double] {
        return [
            .frontal: 0.8,
            .temporal: 0.6,
            .parietal: 0.7,
            .occipital: 0.5,
            .cerebellum: 0.9,
            .brainstem: 0.4
        ]
    }
    
    /// Create default body metrics
    static func defaultBodyMetrics() -> BodyMetrics {
        return BodyMetrics(
            height: 170,
            weight: 70,
            bodyFat: 15.0,
            muscleMass: 45.0
        )
    }
} 