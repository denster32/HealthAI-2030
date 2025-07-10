import SwiftUI

// MARK: - Progress Bar Animations
/// Comprehensive progress bar animations for enhanced user experience
/// Provides smooth, engaging, and informative progress animations for various use cases
public struct ProgressBarAnimations {
    
    // MARK: - Animated Progress Bar
    
    /// Animated progress bar with smooth transitions
    public struct AnimatedProgressBar: View {
        let progress: Double
        let color: Color
        let height: CGFloat
        let showPercentage: Bool
        let animated: Bool
        @State private var animatedProgress: Double = 0
        @State private var shimmerOffset: CGFloat = -200
        
        public init(
            progress: Double,
            color: Color = .blue,
            height: CGFloat = 8,
            showPercentage: Bool = true,
            animated: Bool = true
        ) {
            self.progress = progress
            self.color = color
            self.height = height
            self.showPercentage = showPercentage
            self.animated = animated
        }
        
        public var body: some View {
            VStack(spacing: 8) {
                // Progress bar
                ZStack(alignment: .leading) {
                    // Background
                    RoundedRectangle(cornerRadius: height / 2)
                        .fill(Color.gray.opacity(0.3))
                        .frame(height: height)
                    
                    // Progress fill
                    RoundedRectangle(cornerRadius: height / 2)
                        .fill(
                            LinearGradient(
                                colors: [color, color.opacity(0.8)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: animatedProgress * UIScreen.main.bounds.width * 0.8, height: height)
                        .overlay(
                            // Shimmer effect
                            RoundedRectangle(cornerRadius: height / 2)
                                .fill(
                                    LinearGradient(
                                        colors: [Color.clear, Color.white.opacity(0.3), Color.clear],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .offset(x: shimmerOffset)
                                .clipped()
                        )
                }
                
                // Percentage label
                if showPercentage {
                    HStack {
                        Text("Progress")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        Text("\(Int(animatedProgress * 100))%")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(color)
                    }
                }
            }
            .onAppear {
                startAnimation()
            }
            .onChange(of: progress) { _ in
                startAnimation()
            }
        }
        
        private func startAnimation() {
            if animated {
                withAnimation(.easeInOut(duration: 1.0)) {
                    animatedProgress = progress
                }
                
                withAnimation(.linear(duration: 2.0).repeatForever(autoreverses: false)) {
                    shimmerOffset = 200
                }
            } else {
                animatedProgress = progress
            }
        }
    }
    
    // MARK: - Segmented Progress Bar
    
    /// Progress bar with segmented sections
    public struct SegmentedProgressBar: View {
        let segments: [ProgressSegment]
        let currentSegment: Int
        let animated: Bool
        @State private var animatedSegments: [Double] = []
        
        public init(
            segments: [ProgressSegment],
            currentSegment: Int = 0,
            animated: Bool = true
        ) {
            self.segments = segments
            self.currentSegment = currentSegment
            self.animated = animated
            self._animatedSegments = State(initialValue: Array(repeating: 0, count: segments.count))
        }
        
        public var body: some View {
            VStack(spacing: 12) {
                // Segmented progress bar
                HStack(spacing: 4) {
                    ForEach(Array(segments.enumerated()), id: \.offset) { index, segment in
                        RoundedRectangle(cornerRadius: 4)
                            .fill(segmentColor(for: index))
                            .frame(height: 8)
                            .scaleEffect(x: animatedSegments[index], anchor: .leading)
                            .animation(
                                animated ? .easeInOut(duration: 0.5).delay(Double(index) * 0.1) : .none,
                                value: animatedSegments[index]
                            )
                    }
                }
                
                // Segment labels
                HStack {
                    ForEach(Array(segments.enumerated()), id: \.offset) { index, segment in
                        VStack(spacing: 4) {
                            Circle()
                                .fill(segmentColor(for: index))
                                .frame(width: 8, height: 8)
                            
                            Text(segment.title)
                                .font(.caption)
                                .foregroundColor(index <= currentSegment ? .primary : .secondary)
                        }
                        
                        if index < segments.count - 1 {
                            Spacer()
                        }
                    }
                }
            }
            .onAppear {
                updateSegments()
            }
            .onChange(of: currentSegment) { _ in
                updateSegments()
            }
        }
        
        private func segmentColor(for index: Int) -> Color {
            if index < currentSegment {
                return segments[index].color
            } else if index == currentSegment {
                return segments[index].color.opacity(0.7)
            } else {
                return Color.gray.opacity(0.3)
            }
        }
        
        private func updateSegments() {
            for index in 0..<segments.count {
                let progress: Double = index < currentSegment ? 1.0 : (index == currentSegment ? 0.5 : 0.0)
                animatedSegments[index] = progress
            }
        }
    }
    
    // MARK: - Circular Progress Bar
    
    /// Circular progress bar with smooth animations
    public struct CircularProgressBar: View {
        let progress: Double
        let size: CGFloat
        let lineWidth: CGFloat
        let color: Color
        let showPercentage: Bool
        let animated: Bool
        @State private var animatedProgress: Double = 0
        @State private var rotation: Double = 0
        
        public init(
            progress: Double,
            size: CGFloat = 60,
            lineWidth: CGFloat = 6,
            color: Color = .blue,
            showPercentage: Bool = true,
            animated: Bool = true
        ) {
            self.progress = progress
            self.size = size
            self.lineWidth = lineWidth
            self.color = color
            self.showPercentage = showPercentage
            self.animated = animated
        }
        
        public var body: some View {
            ZStack {
                // Background circle
                Circle()
                    .stroke(Color.gray.opacity(0.3), lineWidth: lineWidth)
                    .frame(width: size, height: size)
                
                // Progress circle
                Circle()
                    .trim(from: 0, to: animatedProgress)
                    .stroke(
                        AngularGradient(
                            gradient: Gradient(colors: [color, color.opacity(0.7)]),
                            center: .center,
                            startAngle: .degrees(-90),
                            endAngle: .degrees(270)
                        ),
                        style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                    )
                    .frame(width: size, height: size)
                    .rotationEffect(.degrees(-90))
                    .rotationEffect(.degrees(rotation))
                
                // Percentage text
                if showPercentage {
                    Text("\(Int(animatedProgress * 100))%")
                        .font(.system(size: size * 0.25, weight: .bold))
                        .foregroundColor(color)
                }
            }
            .onAppear {
                startAnimation()
            }
            .onChange(of: progress) { _ in
                startAnimation()
            }
        }
        
        private func startAnimation() {
            if animated {
                withAnimation(.easeInOut(duration: 1.0)) {
                    animatedProgress = progress
                }
                
                withAnimation(.linear(duration: 2.0).repeatForever(autoreverses: false)) {
                    rotation = 360
                }
            } else {
                animatedProgress = progress
            }
        }
    }
    
    // MARK: - Wave Progress Bar
    
    /// Wave-like progress bar animation
    public struct WaveProgressBar: View {
        let progress: Double
        let color: Color
        let height: CGFloat
        @State private var waveOffset: CGFloat = 0
        @State private var animatedProgress: Double = 0
        
        public init(
            progress: Double,
            color: Color = .blue,
            height: CGFloat = 60
        ) {
            self.progress = progress
            self.color = color
            self.height = height
        }
        
        public var body: some View {
            ZStack {
                // Background
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.gray.opacity(0.3))
                    .frame(height: height)
                
                // Wave fill
                WaveShape(progress: animatedProgress, waveOffset: waveOffset)
                    .fill(
                        LinearGradient(
                            colors: [color, color.opacity(0.7)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(height: height)
                    .clipped()
            }
            .onAppear {
                startAnimation()
            }
            .onChange(of: progress) { _ in
                startAnimation()
            }
        }
        
        private func startAnimation() {
            withAnimation(.easeInOut(duration: 1.0)) {
                animatedProgress = progress
            }
            
            withAnimation(.linear(duration: 2.0).repeatForever(autoreverses: false)) {
                waveOffset = 2 * .pi
            }
        }
    }
    
    // MARK: - Pulsing Progress Bar
    
    /// Progress bar with pulsing animation
    public struct PulsingProgressBar: View {
        let progress: Double
        let color: Color
        let height: CGFloat
        @State private var pulseScale: CGFloat = 1.0
        @State private var animatedProgress: Double = 0
        
        public init(
            progress: Double,
            color: Color = .blue,
            height: CGFloat = 8
        ) {
            self.progress = progress
            self.color = color
            self.height = height
        }
        
        public var body: some View {
            ZStack(alignment: .leading) {
                // Background
                RoundedRectangle(cornerRadius: height / 2)
                    .fill(Color.gray.opacity(0.3))
                    .frame(height: height)
                
                // Progress fill
                RoundedRectangle(cornerRadius: height / 2)
                    .fill(color)
                    .frame(width: animatedProgress * UIScreen.main.bounds.width * 0.8, height: height)
                    .scaleEffect(pulseScale, anchor: .leading)
            }
            .onAppear {
                startAnimation()
            }
            .onChange(of: progress) { _ in
                startAnimation()
            }
        }
        
        private func startAnimation() {
            withAnimation(.easeInOut(duration: 1.0)) {
                animatedProgress = progress
            }
            
            withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
                pulseScale = 1.05
            }
        }
    }
    
    // MARK: - Multi-Step Progress Bar
    
    /// Multi-step progress bar with step indicators
    public struct MultiStepProgressBar: View {
        let steps: [ProgressStep]
        let currentStep: Int
        let animated: Bool
        @State private var animatedStep: Int = 0
        @State private var stepScales: [CGFloat] = []
        
        public init(
            steps: [ProgressStep],
            currentStep: Int = 0,
            animated: Bool = true
        ) {
            self.steps = steps
            self.currentStep = currentStep
            self.animated = animated
            self._stepScales = State(initialValue: Array(repeating: 1.0, count: steps.count))
        }
        
        public var body: some View {
            VStack(spacing: 16) {
                // Progress line
                ZStack {
                    // Background line
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(height: 4)
                    
                    // Progress line
                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [Color.blue, Color.purple],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: progressWidth, height: 4)
                        .animation(animated ? .easeInOut(duration: 0.5) : .none, value: currentStep)
                }
                
                // Step indicators
                HStack {
                    ForEach(Array(steps.enumerated()), id: \.offset) { index, step in
                        VStack(spacing: 8) {
                            ZStack {
                                Circle()
                                    .fill(stepColor(for: index))
                                    .frame(width: 32, height: 32)
                                    .scaleEffect(stepScales[index])
                                
                                if index < currentStep {
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 16, weight: .bold))
                                        .foregroundColor(.white)
                                } else {
                                    Text("\(index + 1)")
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundColor(.white)
                                }
                            }
                            
                            Text(step.title)
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(stepColor(for: index))
                                .multilineTextAlignment(.center)
                        }
                        
                        if index < steps.count - 1 {
                            Spacer()
                        }
                    }
                }
            }
            .onAppear {
                updateSteps()
            }
            .onChange(of: currentStep) { _ in
                updateSteps()
            }
        }
        
        private var progressWidth: CGFloat {
            let progress = Double(currentStep) / Double(max(1, steps.count - 1))
            return UIScreen.main.bounds.width * 0.8 * progress
        }
        
        private func stepColor(for index: Int) -> Color {
            if index < currentStep {
                return .green
            } else if index == currentStep {
                return .blue
            } else {
                return .gray
            }
        }
        
        private func updateSteps() {
            for index in 0..<steps.count {
                let scale: CGFloat = index == currentStep ? 1.2 : 1.0
                withAnimation(animated ? .spring(response: 0.5, dampingFraction: 0.7) : .none) {
                    stepScales[index] = scale
                }
            }
        }
    }
}

// MARK: - Supporting Types

struct ProgressSegment {
    let title: String
    let color: Color
    
    init(title: String, color: Color = .blue) {
        self.title = title
        self.color = color
    }
}

struct ProgressStep {
    let title: String
    let description: String?
    
    init(title: String, description: String? = nil) {
        self.title = title
        self.description = description
    }
}

struct WaveShape: Shape {
    let progress: Double
    let waveOffset: CGFloat
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        let width = rect.width
        let height = rect.height
        let waveHeight = height * 0.1
        let progressHeight = height * progress
        
        path.move(to: CGPoint(x: 0, y: height))
        
        // Draw wave pattern
        for x in stride(from: 0, through: width, by: 1) {
            let relativeX = x / width
            let waveY = sin(relativeX * 4 * .pi + waveOffset) * waveHeight
            let y = height - progressHeight + waveY
            path.addLine(to: CGPoint(x: x, y: y))
        }
        
        path.addLine(to: CGPoint(x: width, y: height))
        path.closeSubpath()
        
        return path
    }
}

// MARK: - Preview

struct ProgressBarAnimations_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 30) {
            AnimatedProgressBar(progress: 0.75)
            
            SegmentedProgressBar(
                segments: [
                    ProgressSegment(title: "Step 1", color: .blue),
                    ProgressSegment(title: "Step 2", color: .green),
                    ProgressSegment(title: "Step 3", color: .orange)
                ],
                currentSegment: 1
            )
            
            CircularProgressBar(progress: 0.6)
            
            WaveProgressBar(progress: 0.7)
            
            PulsingProgressBar(progress: 0.8)
            
            MultiStepProgressBar(
                steps: [
                    ProgressStep(title: "Setup"),
                    ProgressStep(title: "Configure"),
                    ProgressStep(title: "Test"),
                    ProgressStep(title: "Complete")
                ],
                currentStep: 2
            )
        }
        .padding()
        .previewLayout(.sizeThatFits)
    }
} 