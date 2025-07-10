import SwiftUI

// MARK: - Progress Indicator Animations
/// Comprehensive progress indicator animations for enhanced user experience
/// Provides smooth, accessible, and engaging progress animations for various use cases
public struct ProgressIndicatorAnimations {
    
    // MARK: - Circular Progress Animation
    
    /// Circular progress indicator with smooth animations
    public struct CircularProgressAnimation: View {
        let progress: Double
        let size: CGFloat
        let lineWidth: CGFloat
        let color: Color
        let showPercentage: Bool
        @State private var animatedProgress: Double = 0
        @State private var rotation: Double = 0
        
        public init(
            progress: Double,
            size: CGFloat = 60,
            lineWidth: CGFloat = 6,
            color: Color = .blue,
            showPercentage: Bool = true
        ) {
            self.progress = progress
            self.size = size
            self.lineWidth = lineWidth
            self.color = color
            self.showPercentage = showPercentage
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
            withAnimation(.easeInOut(duration: 1.0)) {
                animatedProgress = progress
            }
            
            withAnimation(.linear(duration: 2.0).repeatForever(autoreverses: false)) {
                rotation = 360
            }
        }
    }
    
    // MARK: - Linear Progress Animation
    
    /// Linear progress bar with smooth animations
    public struct LinearProgressAnimation: View {
        let progress: Double
        let height: CGFloat
        let color: Color
        let showLabel: Bool
        @State private var animatedProgress: Double = 0
        @State private var shimmerOffset: CGFloat = -200
        
        public init(
            progress: Double,
            height: CGFloat = 8,
            color: Color = .blue,
            showLabel: Bool = true
        ) {
            self.progress = progress
            self.height = height
            self.color = color
            self.showLabel = showLabel
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
                
                // Progress label
                if showLabel {
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
            withAnimation(.easeInOut(duration: 1.0)) {
                animatedProgress = progress
            }
            
            withAnimation(.linear(duration: 2.0).repeatForever(autoreverses: false)) {
                shimmerOffset = 200
            }
        }
    }
    
    // MARK: - Pulsing Progress Animation
    
    /// Pulsing progress indicator for indeterminate loading
    public struct PulsingProgressAnimation: View {
        let color: Color
        let size: CGFloat
        @State private var scale: CGFloat = 1.0
        @State private var opacity: Double = 1.0
        @State private var rotation: Double = 0
        
        public init(
            color: Color = .blue,
            size: CGFloat = 40
        ) {
            self.color = color
            self.size = size
        }
        
        public var body: some View {
            ZStack {
                // Multiple pulsing circles
                ForEach(0..<3, id: \.self) { index in
                    Circle()
                        .fill(color.opacity(0.3))
                        .frame(width: size, height: size)
                        .scaleEffect(scale)
                        .opacity(opacity)
                        .animation(
                            .easeInOut(duration: 1.5)
                            .repeatForever(autoreverses: true)
                            .delay(Double(index) * 0.2),
                            value: scale
                        )
                }
                
                // Center indicator
                Circle()
                    .fill(color)
                    .frame(width: size * 0.4, height: size * 0.4)
                    .rotationEffect(.degrees(rotation))
            }
            .onAppear {
                startAnimation()
            }
        }
        
        private func startAnimation() {
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                scale = 1.5
                opacity = 0.0
            }
            
            withAnimation(.linear(duration: 2.0).repeatForever(autoreverses: false)) {
                rotation = 360
            }
        }
    }
    
    // MARK: - Dots Progress Animation
    
    /// Animated dots progress indicator
    public struct DotsProgressAnimation: View {
        let color: Color
        let dotSize: CGFloat
        @State private var dotScales: [CGFloat] = [1.0, 1.0, 1.0]
        @State private var dotOpacities: [Double] = [1.0, 1.0, 1.0]
        
        public init(
            color: Color = .blue,
            dotSize: CGFloat = 8
        ) {
            self.color = color
            self.dotSize = dotSize
        }
        
        public var body: some View {
            HStack(spacing: 8) {
                ForEach(0..<3, id: \.self) { index in
                    Circle()
                        .fill(color)
                        .frame(width: dotSize, height: dotSize)
                        .scaleEffect(dotScales[index])
                        .opacity(dotOpacities[index])
                        .animation(
                            .easeInOut(duration: 0.6)
                            .repeatForever(autoreverses: true)
                            .delay(Double(index) * 0.2),
                            value: dotScales[index]
                        )
                }
            }
            .onAppear {
                startAnimation()
            }
        }
        
        private func startAnimation() {
            for index in 0..<3 {
                DispatchQueue.main.asyncAfter(deadline: .now() + Double(index) * 0.2) {
                    withAnimation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true)) {
                        dotScales[index] = 1.5
                        dotOpacities[index] = 0.5
                    }
                }
            }
        }
    }
    
    // MARK: - Spinning Progress Animation
    
    /// Spinning progress indicator with customizable segments
    public struct SpinningProgressAnimation: View {
        let progress: Double
        let segments: Int
        let color: Color
        let size: CGFloat
        @State private var rotation: Double = 0
        @State private var animatedProgress: Double = 0
        
        public init(
            progress: Double,
            segments: Int = 8,
            color: Color = .blue,
            size: CGFloat = 50
        ) {
            self.progress = progress
            self.segments = segments
            self.color = color
            self.size = size
        }
        
        public var body: some View {
            ZStack {
                // Background segments
                ForEach(0..<segments, id: \.self) { index in
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 3, height: size * 0.3)
                        .offset(y: -size * 0.15)
                        .rotationEffect(.degrees(Double(index) * 360 / Double(segments)))
                }
                
                // Active segments
                ForEach(0..<Int(animatedProgress * Double(segments)), id: \.self) { index in
                    RoundedRectangle(cornerRadius: 2)
                        .fill(color)
                        .frame(width: 3, height: size * 0.3)
                        .offset(y: -size * 0.15)
                        .rotationEffect(.degrees(Double(index) * 360 / Double(segments)))
                }
            }
            .frame(width: size, height: size)
            .rotationEffect(.degrees(rotation))
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
            
            withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                rotation = 360
            }
        }
    }
    
    // MARK: - Wave Progress Animation
    
    /// Wave-like progress indicator
    public struct WaveProgressAnimation: View {
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
    
    // MARK: - Step Progress Animation
    
    /// Step-by-step progress indicator
    public struct StepProgressAnimation: View {
        let steps: [String]
        let currentStep: Int
        let color: Color
        @State private var animatedStep: Int = 0
        @State private var stepScales: [CGFloat] = []
        
        public init(
            steps: [String],
            currentStep: Int,
            color: Color = .blue
        ) {
            self.steps = steps
            self.currentStep = currentStep
            self.color = color
            self.stepScales = Array(repeating: 1.0, count: steps.count)
        }
        
        public var body: some View {
            HStack(spacing: 20) {
                ForEach(Array(steps.enumerated()), id: \.offset) { index, step in
                    VStack(spacing: 8) {
                        // Step circle
                        ZStack {
                            Circle()
                                .fill(index <= animatedStep ? color : Color.gray.opacity(0.3))
                                .frame(width: 40, height: 40)
                                .scaleEffect(stepScales[index])
                            
                            if index < animatedStep {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(.white)
                            } else {
                                Text("\(index + 1)")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(index <= animatedStep ? .white : .gray)
                            }
                        }
                        
                        // Step label
                        Text(step)
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(index <= animatedStep ? .primary : .secondary)
                            .multilineTextAlignment(.center)
                    }
                    
                    // Connector line
                    if index < steps.count - 1 {
                        Rectangle()
                            .fill(index < animatedStep ? color : Color.gray.opacity(0.3))
                            .frame(width: 20, height: 2)
                    }
                }
            }
            .onAppear {
                startAnimation()
            }
            .onChange(of: currentStep) { _ in
                startAnimation()
            }
        }
        
        private func startAnimation() {
            for index in 0..<steps.count {
                DispatchQueue.main.asyncAfter(deadline: .now() + Double(index) * 0.3) {
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                        if index <= currentStep {
                            animatedStep = index
                            stepScales[index] = 1.2
                        }
                    }
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            stepScales[index] = 1.0
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Supporting Views

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

struct ProgressIndicatorAnimations_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 30) {
            CircularProgressAnimation(progress: 0.75)
            
            LinearProgressAnimation(progress: 0.6)
            
            PulsingProgressAnimation()
            
            DotsProgressAnimation()
            
            SpinningProgressAnimation(progress: 0.8)
            
            WaveProgressAnimation(progress: 0.7)
            
            StepProgressAnimation(
                steps: ["Setup", "Configure", "Test", "Complete"],
                currentStep: 2
            )
        }
        .padding()
        .previewLayout(.sizeThatFits)
    }
} 