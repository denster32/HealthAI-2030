import SwiftUI

// MARK: - Animated Health Explanations
/// Comprehensive animated health explanations for enhanced learning
/// Provides interactive animations to explain complex health concepts
public struct AnimatedHealthExplanations {
    
    // MARK: - Heart Animation Component
    
    /// Animated heart with heartbeat visualization
    public struct HeartAnimation: View {
        let heartRate: Double
        let isHealthy: Bool
        @State private var heartScale: CGFloat = 1.0
        @State private var heartColor: Color = .red
        @State private var pulseOpacity: Double = 0.0
        @State private var showEKG: Bool = false
        
        public init(
            heartRate: Double = 72.0,
            isHealthy: Bool = true
        ) {
            self.heartRate = heartRate
            self.isHealthy = isHealthy
        }
        
        public var body: some View {
            VStack(spacing: 20) {
                ZStack {
                    // Pulse rings
                    ForEach(0..<3, id: \.self) { index in
                        Circle()
                            .stroke(heartColor.opacity(0.3), lineWidth: 2)
                            .frame(width: 120 + CGFloat(index * 40), height: 120 + CGFloat(index * 40))
                            .scaleEffect(pulseOpacity)
                            .opacity(2.0 - pulseOpacity)
                            .animation(
                                .easeOut(duration: 2.0)
                                .repeatForever(autoreverses: false)
                                .delay(Double(index) * 0.3),
                                value: pulseOpacity
                            )
                    }
                    
                    // Heart shape
                    HeartShape()
                        .fill(heartColor)
                        .frame(width: 100, height: 100)
                        .scaleEffect(heartScale)
                        .animation(
                            .easeInOut(duration: 60.0 / heartRate)
                            .repeatForever(autoreverses: true),
                            value: heartScale
                        )
                        .onTapGesture {
                            showEKG.toggle()
                        }
                }
                
                // Heart rate display
                VStack(spacing: 8) {
                    Text("\(Int(heartRate)) BPM")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(heartColor)
                    
                    Text(isHealthy ? "Normal Heart Rate" : "Abnormal Heart Rate")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(isHealthy ? .green : .red)
                }
                
                // EKG display
                if showEKG {
                    EKGView(heartRate: heartRate, isHealthy: isHealthy)
                        .frame(height: 100)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                        .transition(.opacity.combined(with: .scale))
                }
            }
            .onAppear {
                startHeartbeat()
                startPulse()
            }
        }
        
        private func startHeartbeat() {
            heartColor = isHealthy ? .red : .orange
            
            withAnimation(.easeInOut(duration: 60.0 / heartRate).repeatForever(autoreverses: true)) {
                heartScale = 1.2
            }
        }
        
        private func startPulse() {
            withAnimation(.easeOut(duration: 2.0).repeatForever(autoreverses: false)) {
                pulseOpacity = 2.0
            }
        }
    }
    
    // MARK: - Blood Flow Animation Component
    
    /// Animated blood flow through vessels
    public struct BloodFlowAnimation: View {
        let flowRate: Double
        let vesselType: VesselType
        @State private var bloodCells: [BloodCell] = []
        @State private var animationTimer: Timer?
        
        public init(
            flowRate: Double = 1.0,
            vesselType: VesselType = .artery
        ) {
            self.flowRate = flowRate
            self.vesselType = vesselType
        }
        
        public var body: some View {
            VStack(spacing: 16) {
                // Vessel and blood flow
                ZStack {
                    // Vessel
                    VesselShape(type: vesselType)
                        .stroke(vesselType.color, lineWidth: vesselType.lineWidth)
                        .frame(width: 200, height: 60)
                    
                    // Blood cells
                    ForEach(bloodCells) { cell in
                        Circle()
                            .fill(cell.color)
                            .frame(width: cell.size, height: cell.size)
                            .offset(x: cell.offset)
                            .opacity(cell.opacity)
                    }
                }
                
                // Flow rate indicator
                VStack(spacing: 4) {
                    Text("Blood Flow Rate")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.primary)
                    
                    Text("\(String(format: "%.1f", flowRate))x Normal")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(vesselType.color)
                }
            }
            .onAppear {
                startBloodFlow()
            }
            .onDisappear {
                animationTimer?.invalidate()
            }
        }
        
        private func startBloodFlow() {
            // Create initial blood cells
            for i in 0..<10 {
                let cell = BloodCell(
                    id: i,
                    offset: CGFloat(i * 20) - 100,
                    color: vesselType.bloodColor,
                    size: CGFloat.random(in: 4...8),
                    opacity: Double.random(in: 0.6...1.0)
                )
                bloodCells.append(cell)
            }
            
            // Animate blood flow
            animationTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
                withAnimation(.linear(duration: 0.1)) {
                    for i in 0..<bloodCells.count {
                        bloodCells[i].offset += 2 * flowRate
                        
                        // Reset cell position when it goes off screen
                        if bloodCells[i].offset > 120 {
                            bloodCells[i].offset = -120
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Lung Animation Component
    
    /// Animated lungs with breathing visualization
    public struct LungAnimation: View {
        let breathingRate: Double
        let isHealthy: Bool
        @State private var lungScale: CGFloat = 1.0
        @State private var isInhaling: Bool = true
        @State private var oxygenLevel: Double = 98.0
        
        public init(
            breathingRate: Double = 12.0,
            isHealthy: Bool = true
        ) {
            self.breathingRate = breathingRate
            self.isHealthy = isHealthy
        }
        
        public var body: some View {
            VStack(spacing: 20) {
                HStack(spacing: 40) {
                    // Left lung
                    LungShape()
                        .fill(isHealthy ? Color.blue.opacity(0.6) : Color.orange.opacity(0.6))
                        .frame(width: 80, height: 120)
                        .scaleEffect(lungScale)
                        .animation(
                            .easeInOut(duration: 60.0 / breathingRate)
                            .repeatForever(autoreverses: true),
                            value: lungScale
                        )
                    
                    // Right lung
                    LungShape()
                        .fill(isHealthy ? Color.blue.opacity(0.6) : Color.orange.opacity(0.6))
                        .frame(width: 80, height: 120)
                        .scaleEffect(lungScale)
                        .animation(
                            .easeInOut(duration: 60.0 / breathingRate)
                            .repeatForever(autoreverses: true),
                            value: lungScale
                        )
                }
                
                // Breathing indicator
                VStack(spacing: 8) {
                    Text(isInhaling ? "Inhaling" : "Exhaling")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(isHealthy ? .blue : .orange)
                        .animation(.easeInOut(duration: 60.0 / breathingRate), value: isInhaling)
                    
                    Text("\(Int(breathingRate)) breaths/min")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.secondary)
                }
                
                // Oxygen saturation
                VStack(spacing: 4) {
                    Text("Oxygen Saturation")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.primary)
                    
                    Text("\(Int(oxygenLevel))%")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(oxygenLevel > 95 ? .green : .orange)
                }
            }
            .onAppear {
                startBreathing()
            }
        }
        
        private func startBreathing() {
            withAnimation(.easeInOut(duration: 60.0 / breathingRate).repeatForever(autoreverses: true)) {
                lungScale = 1.3
            }
            
            // Update breathing state
            Timer.scheduledTimer(withTimeInterval: 60.0 / breathingRate / 2, repeats: true) { _ in
                withAnimation(.easeInOut(duration: 0.5)) {
                    isInhaling.toggle()
                }
            }
        }
    }
    
    // MARK: - Brain Activity Animation Component
    
    /// Animated brain with neural activity visualization
    public struct BrainActivityAnimation: View {
        let activityLevel: Double
        let isHealthy: Bool
        @State private var neuralConnections: [NeuralConnection] = []
        @State private var brainGlow: Double = 0.0
        
        public init(
            activityLevel: Double = 0.7,
            isHealthy: Bool = true
        ) {
            self.activityLevel = activityLevel
            self.isHealthy = isHealthy
        }
        
        public var body: some View {
            VStack(spacing: 20) {
                ZStack {
                    // Brain outline
                    BrainShape()
                        .stroke(isHealthy ? Color.purple : Color.orange, lineWidth: 3)
                        .frame(width: 120, height: 100)
                    
                    // Neural connections
                    ForEach(neuralConnections) { connection in
                        Path { path in
                            path.move(to: connection.startPoint)
                            path.addLine(to: connection.endPoint)
                        }
                        .stroke(connection.color, lineWidth: connection.width)
                        .opacity(connection.opacity)
                    }
                    
                    // Brain glow effect
                    BrainShape()
                        .fill(isHealthy ? Color.purple.opacity(0.3) : Color.orange.opacity(0.3))
                        .frame(width: 120, height: 100)
                        .scaleEffect(1.0 + brainGlow * 0.1)
                        .opacity(brainGlow)
                }
                
                // Activity indicator
                VStack(spacing: 8) {
                    Text("Brain Activity")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.primary)
                    
                    ProgressView(value: activityLevel)
                        .progressViewStyle(LinearProgressViewStyle(tint: isHealthy ? .purple : .orange))
                        .frame(width: 150)
                    
                    Text("\(Int(activityLevel * 100))%")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(isHealthy ? .purple : .orange)
                }
            }
            .onAppear {
                startNeuralActivity()
            }
        }
        
        private func startNeuralActivity() {
            // Create neural connections
            for _ in 0..<15 {
                let connection = NeuralConnection(
                    startPoint: CGPoint(
                        x: CGFloat.random(in: -50...50),
                        y: CGFloat.random(in: -40...40)
                    ),
                    endPoint: CGPoint(
                        x: CGFloat.random(in: -50...50),
                        y: CGFloat.random(in: -40...40)
                    ),
                    color: isHealthy ? .purple : .orange,
                    width: CGFloat.random(in: 1...3),
                    opacity: Double.random(in: 0.3...0.8)
                )
                neuralConnections.append(connection)
            }
            
            // Animate brain glow
            withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
                brainGlow = 0.5
            }
        }
    }
    
    // MARK: - Digestive System Animation Component
    
    /// Animated digestive system with food processing
    public struct DigestiveSystemAnimation: View {
        let foodType: FoodType
        let processingSpeed: Double
        @State private var foodParticles: [FoodParticle] = []
        @State private var currentStage: DigestiveStage = .mouth
        
        public init(
            foodType: FoodType = .healthy,
            processingSpeed: Double = 1.0
        ) {
            self.foodType = foodType
            self.processingSpeed = processingSpeed
        }
        
        public var body: some View {
            VStack(spacing: 20) {
                // Digestive system visualization
                ZStack {
                    // System outline
                    DigestiveSystemShape()
                        .stroke(Color.brown, lineWidth: 2)
                        .frame(width: 200, height: 150)
                    
                    // Food particles
                    ForEach(foodParticles) { particle in
                        Circle()
                            .fill(particle.color)
                            .frame(width: particle.size, height: particle.size)
                            .offset(particle.position)
                            .opacity(particle.opacity)
                    }
                }
                
                // Stage indicator
                VStack(spacing: 8) {
                    Text("Digestive Stage")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.primary)
                    
                    Text(currentStage.description)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.brown)
                }
            }
            .onAppear {
                startDigestion()
            }
        }
        
        private func startDigestion() {
            // Create food particles
            for i in 0..<8 {
                let particle = FoodParticle(
                    id: i,
                    position: CGPoint(x: -80, y: CGFloat.random(in: -20...20)),
                    color: foodType.color,
                    size: CGFloat.random(in: 4...8),
                    opacity: 1.0
                )
                foodParticles.append(particle)
            }
            
            // Animate digestion process
            animateDigestion()
        }
        
        private func animateDigestion() {
            let stages: [DigestiveStage] = [.mouth, .esophagus, .stomach, .intestines]
            var currentStageIndex = 0
            
            Timer.scheduledTimer(withTimeInterval: 2.0 / processingSpeed, repeats: true) { timer in
                if currentStageIndex < stages.count {
                    currentStage = stages[currentStageIndex]
                    
                    // Move food particles
                    withAnimation(.easeInOut(duration: 2.0 / processingSpeed)) {
                        for i in 0..<foodParticles.count {
                            let stagePosition = getStagePosition(stages[currentStageIndex])
                            foodParticles[i].position = CGPoint(
                                x: stagePosition.x + CGFloat.random(in: -10...10),
                                y: stagePosition.y + CGFloat.random(in: -10...10)
                            )
                            
                            if currentStageIndex == stages.count - 1 {
                                foodParticles[i].opacity = 0.0
                            }
                        }
                    }
                    
                    currentStageIndex += 1
                } else {
                    timer.invalidate()
                }
            }
        }
        
        private func getStagePosition(_ stage: DigestiveStage) -> CGPoint {
            switch stage {
            case .mouth: return CGPoint(x: -60, y: -40)
            case .esophagus: return CGPoint(x: -20, y: -20)
            case .stomach: return CGPoint(x: 20, y: 0)
            case .intestines: return CGPoint(x: 60, y: 20)
            }
        }
    }
}

// MARK: - Supporting Types

struct BloodCell: Identifiable {
    let id: Int
    var offset: CGFloat
    let color: Color
    let size: CGFloat
    let opacity: Double
}

enum VesselType {
    case artery
    case vein
    case capillary
    
    var color: Color {
        switch self {
        case .artery: return .red
        case .vein: return .blue
        case .capillary: return .purple
        }
    }
    
    var bloodColor: Color {
        switch self {
        case .artery: return .red
        case .vein: return .darkRed
        case .capillary: return .red
        }
    }
    
    var lineWidth: CGFloat {
        switch self {
        case .artery: return 4
        case .vein: return 3
        case .capillary: return 1
        }
    }
}

struct NeuralConnection: Identifiable {
    let id = UUID()
    let startPoint: CGPoint
    let endPoint: CGPoint
    let color: Color
    let width: CGFloat
    let opacity: Double
}

enum FoodType {
    case healthy
    case processed
    case sugary
    
    var color: Color {
        switch self {
        case .healthy: return .green
        case .processed: return .orange
        case .sugary: return .pink
        }
    }
}

struct FoodParticle: Identifiable {
    let id: Int
    var position: CGPoint
    let color: Color
    let size: CGFloat
    var opacity: Double
}

enum DigestiveStage {
    case mouth
    case esophagus
    case stomach
    case intestines
    
    var description: String {
        switch self {
        case .mouth: return "Mouth - Chewing"
        case .esophagus: return "Esophagus - Transport"
        case .stomach: return "Stomach - Breakdown"
        case .intestines: return "Intestines - Absorption"
        }
    }
}

// MARK: - Custom Shapes

struct HeartShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        let width = rect.width
        let height = rect.height
        
        path.move(to: CGPoint(x: width * 0.5, y: height * 0.8))
        path.addCurve(
            to: CGPoint(x: 0, y: height * 0.3),
            control1: CGPoint(x: width * 0.5, y: height * 0.6),
            control2: CGPoint(x: 0, y: height * 0.4)
        )
        path.addCurve(
            to: CGPoint(x: width * 0.5, y: 0),
            control1: CGPoint(x: 0, y: height * 0.2),
            control2: CGPoint(x: width * 0.2, y: 0)
        )
        path.addCurve(
            to: CGPoint(x: width, y: height * 0.3),
            control1: CGPoint(x: width * 0.8, y: 0),
            control2: CGPoint(x: width, y: height * 0.2)
        )
        path.addCurve(
            to: CGPoint(x: width * 0.5, y: height * 0.8),
            control1: CGPoint(x: width, y: height * 0.4),
            control2: CGPoint(x: width * 0.5, y: height * 0.6)
        )
        
        return path
    }
}

struct VesselShape: Shape {
    let type: VesselType
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        let width = rect.width
        let height = rect.height
        
        switch type {
        case .artery:
            path.move(to: CGPoint(x: 0, y: height * 0.5))
            path.addLine(to: CGPoint(x: width, y: height * 0.5))
        case .vein:
            path.move(to: CGPoint(x: 0, y: height * 0.5))
            path.addCurve(
                to: CGPoint(x: width, y: height * 0.5),
                control1: CGPoint(x: width * 0.3, y: height * 0.3),
                control2: CGPoint(x: width * 0.7, y: height * 0.7)
            )
        case .capillary:
            path.move(to: CGPoint(x: 0, y: height * 0.5))
            path.addCurve(
                to: CGPoint(x: width, y: height * 0.5),
                control1: CGPoint(x: width * 0.2, y: height * 0.2),
                control2: CGPoint(x: width * 0.4, y: height * 0.8),
                control3: CGPoint(x: width * 0.6, y: height * 0.2),
                control4: CGPoint(x: width * 0.8, y: height * 0.8)
            )
        }
        
        return path
    }
}

struct LungShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        let width = rect.width
        let height = rect.height
        
        path.move(to: CGPoint(x: width * 0.5, y: 0))
        path.addCurve(
            to: CGPoint(x: 0, y: height * 0.7),
            control1: CGPoint(x: width * 0.2, y: height * 0.3),
            control2: CGPoint(x: 0, y: height * 0.5)
        )
        path.addCurve(
            to: CGPoint(x: width * 0.5, y: height),
            control1: CGPoint(x: 0, y: height * 0.9),
            control2: CGPoint(x: width * 0.2, y: height)
        )
        path.addCurve(
            to: CGPoint(x: width, y: height * 0.7),
            control1: CGPoint(x: width * 0.8, y: height),
            control2: CGPoint(x: width, y: height * 0.9)
        )
        path.addCurve(
            to: CGPoint(x: width * 0.5, y: 0),
            control1: CGPoint(x: width, y: height * 0.5),
            control2: CGPoint(x: width * 0.8, y: height * 0.3)
        )
        
        return path
    }
}

struct BrainShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        let width = rect.width
        let height = rect.height
        
        path.move(to: CGPoint(x: width * 0.5, y: 0))
        path.addCurve(
            to: CGPoint(x: width, y: height * 0.3),
            control1: CGPoint(x: width * 0.8, y: height * 0.1),
            control2: CGPoint(x: width, y: height * 0.2)
        )
        path.addCurve(
            to: CGPoint(x: width * 0.8, y: height * 0.7),
            control1: CGPoint(x: width, y: height * 0.5),
            control2: CGPoint(x: width * 0.9, y: height * 0.6)
        )
        path.addCurve(
            to: CGPoint(x: width * 0.5, y: height),
            control1: CGPoint(x: width * 0.7, y: height * 0.8),
            control2: CGPoint(x: width * 0.6, y: height)
        )
        path.addCurve(
            to: CGPoint(x: width * 0.2, y: height * 0.7),
            control1: CGPoint(x: width * 0.4, y: height),
            control2: CGPoint(x: width * 0.3, y: height * 0.8)
        )
        path.addCurve(
            to: CGPoint(x: 0, y: height * 0.3),
            control1: CGPoint(x: width * 0.1, y: height * 0.6),
            control2: CGPoint(x: 0, y: height * 0.5)
        )
        path.addCurve(
            to: CGPoint(x: width * 0.5, y: 0),
            control1: CGPoint(x: 0, y: height * 0.2),
            control2: CGPoint(x: width * 0.2, y: height * 0.1)
        )
        
        return path
    }
}

struct DigestiveSystemShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        let width = rect.width
        let height = rect.height
        
        // Mouth
        path.move(to: CGPoint(x: width * 0.3, y: height * 0.2))
        path.addLine(to: CGPoint(x: width * 0.7, y: height * 0.2))
        
        // Esophagus
        path.move(to: CGPoint(x: width * 0.5, y: height * 0.2))
        path.addLine(to: CGPoint(x: width * 0.5, y: height * 0.4))
        
        // Stomach
        path.addEllipse(in: CGRect(x: width * 0.4, y: height * 0.4, width: width * 0.2, height: height * 0.2))
        
        // Intestines
        path.move(to: CGPoint(x: width * 0.6, y: height * 0.5))
        path.addCurve(
            to: CGPoint(x: width * 0.8, y: height * 0.7),
            control1: CGPoint(x: width * 0.7, y: height * 0.6),
            control2: CGPoint(x: width * 0.8, y: height * 0.6)
        )
        
        return path
    }
}

struct EKGView: View {
    let heartRate: Double
    let isHealthy: Bool
    @State private var ekgOffset: CGFloat = 0
    
    var body: some View {
        Path { path in
            let width: CGFloat = 300
            let height: CGFloat = 60
            let step: CGFloat = 2
            
            path.move(to: CGPoint(x: 0, y: height * 0.5))
            
            for x in stride(from: 0, through: width, by: step) {
                let normalizedX = x / width
                let frequency = heartRate / 60.0
                let y = height * 0.5 + sin(normalizedX * 2 * .pi * frequency + ekgOffset) * 20
                path.addLine(to: CGPoint(x: x, y: y))
            }
        }
        .stroke(isHealthy ? Color.green : Color.red, lineWidth: 2)
        .onAppear {
            withAnimation(.linear(duration: 2.0).repeatForever(autoreverses: false)) {
                ekgOffset = 2 * .pi
            }
        }
    }
}

// MARK: - Preview

struct AnimatedHealthExplanations_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 30) {
            HeartAnimation(heartRate: 75, isHealthy: true)
            
            BloodFlowAnimation(flowRate: 1.2, vesselType: .artery)
            
            LungAnimation(breathingRate: 14, isHealthy: true)
            
            BrainActivityAnimation(activityLevel: 0.8, isHealthy: true)
            
            DigestiveSystemAnimation(foodType: .healthy, processingSpeed: 1.0)
        }
        .padding()
        .previewLayout(.sizeThatFits)
    }
} 