import SwiftUI

// MARK: - Loading States
/// Comprehensive loading state components for HealthAI 2030
/// Provides loading animations, skeleton screens, and progress indicators
public struct LoadingStates {
    
    // MARK: - Skeleton Loading Components
    
    /// Skeleton card for health data loading
    public struct HealthDataSkeletonCard: View {
        let title: String
        let showSubtitle: Bool
        
        public init(title: String, showSubtitle: Bool = true) {
            self.title = title
            self.showSubtitle = showSubtitle
        }
        
        public var body: some View {
            VStack(alignment: .leading, spacing: 12) {
                // Title skeleton
                Rectangle()
                    .fill(Color(.systemGray5))
                    .frame(height: 20)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .cornerRadius(4)
                
                if showSubtitle {
                    Rectangle()
                        .fill(Color(.systemGray6))
                        .frame(height: 16)
                        .frame(maxWidth: 0.6, alignment: .leading)
                        .cornerRadius(4)
                }
                
                // Value skeleton
                Rectangle()
                    .fill(Color(.systemGray4))
                    .frame(height: 32)
                    .frame(maxWidth: 0.4, alignment: .leading)
                    .cornerRadius(6)
                
                // Chart skeleton
                HStack(spacing: 4) {
                    ForEach(0..<7, id: \.self) { _ in
                        Rectangle()
                            .fill(Color(.systemGray5))
                            .frame(height: CGFloat.random(in: 20...60))
                            .cornerRadius(2)
                    }
                }
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
            .shimmer()
        }
    }
    
    /// Skeleton list item for health data
    public struct HealthDataSkeletonListItem: View {
        public init() {}
        
        public var body: some View {
            HStack(spacing: 12) {
                // Icon skeleton
                Circle()
                    .fill(Color(.systemGray5))
                    .frame(width: 40, height: 40)
                    .shimmer()
                
                VStack(alignment: .leading, spacing: 8) {
                    // Title skeleton
                    Rectangle()
                        .fill(Color(.systemGray5))
                        .frame(height: 16)
                        .frame(maxWidth: 0.7, alignment: .leading)
                        .cornerRadius(4)
                    
                    // Subtitle skeleton
                    Rectangle()
                        .fill(Color(.systemGray6))
                        .frame(height: 14)
                        .frame(maxWidth: 0.5, alignment: .leading)
                        .cornerRadius(4)
                }
                
                Spacer()
                
                // Value skeleton
                Rectangle()
                    .fill(Color(.systemGray4))
                    .frame(width: 60, height: 20)
                    .cornerRadius(6)
            }
            .padding(.vertical, 8)
            .shimmer()
        }
    }
    
    /// Skeleton chart for data visualization
    public struct ChartSkeleton: View {
        let chartType: ChartType
        
        public init(chartType: ChartType = .line) {
            self.chartType = chartType
        }
        
        public var body: some View {
            VStack(spacing: 16) {
                // Chart title skeleton
                Rectangle()
                    .fill(Color(.systemGray5))
                    .frame(height: 20)
                    .frame(maxWidth: 0.6, alignment: .leading)
                    .cornerRadius(4)
                
                // Chart area skeleton
                ZStack {
                    Rectangle()
                        .fill(Color(.systemGray6))
                        .cornerRadius(8)
                    
                    switch chartType {
                    case .line:
                        LineChartSkeleton()
                    case .bar:
                        BarChartSkeleton()
                    case .pie:
                        PieChartSkeleton()
                    }
                }
                .frame(height: 200)
                
                // Legend skeleton
                HStack(spacing: 16) {
                    ForEach(0..<3, id: \.self) { _ in
                        HStack(spacing: 8) {
                            Circle()
                                .fill(Color(.systemGray5))
                                .frame(width: 12, height: 12)
                            
                            Rectangle()
                                .fill(Color(.systemGray5))
                                .frame(width: 40, height: 12)
                                .cornerRadius(4)
                        }
                    }
                }
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
            .shimmer()
        }
    }
    
    // MARK: - Loading Animations
    
    /// Pulsing loading indicator
    public struct PulsingLoader: View {
        @State private var isAnimating = false
        
        public init() {}
        
        public var body: some View {
            Circle()
                .fill(Color.blue)
                .frame(width: 20, height: 20)
                .scaleEffect(isAnimating ? 1.2 : 0.8)
                .opacity(isAnimating ? 0.5 : 1.0)
                .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: isAnimating)
                .onAppear {
                    isAnimating = true
                }
        }
    }
    
    /// Rotating loading spinner
    public struct RotatingSpinner: View {
        @State private var isRotating = false
        
        public init() {}
        
        public var body: some View {
            ZStack {
                Circle()
                    .stroke(Color.blue.opacity(0.3), lineWidth: 4)
                    .frame(width: 40, height: 40)
                
                Circle()
                    .trim(from: 0, to: 0.7)
                    .stroke(Color.blue, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                    .frame(width: 40, height: 40)
                    .rotationEffect(.degrees(isRotating ? 360 : 0))
                    .animation(.linear(duration: 1.0).repeatForever(autoreverses: false), value: isRotating)
                    .onAppear {
                        isRotating = true
                    }
            }
        }
    }
    
    /// Health data loading indicator
    public struct HealthDataLoader: View {
        let message: String
        @State private var dots = ""
        
        public init(message: String = "Loading health data") {
            self.message = message
        }
        
        public var body: some View {
            VStack(spacing: 16) {
                RotatingSpinner()
                
                Text("\(message)\(dots)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .onAppear {
                        Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { _ in
                            if dots.count < 3 {
                                dots += "."
                            } else {
                                dots = ""
                            }
                        }
                    }
            }
            .padding()
        }
    }
    
    // MARK: - Progress Indicators
    
    /// Linear progress bar
    public struct LinearProgressBar: View {
        let progress: Double
        let color: Color
        let showPercentage: Bool
        
        public init(progress: Double, color: Color = .blue, showPercentage: Bool = true) {
            self.progress = min(max(progress, 0), 1)
            self.color = color
            self.showPercentage = showPercentage
        }
        
        public var body: some View {
            VStack(spacing: 8) {
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        Rectangle()
                            .fill(Color(.systemGray5))
                            .frame(height: 8)
                            .cornerRadius(4)
                        
                        Rectangle()
                            .fill(color)
                            .frame(width: geometry.size.width * progress, height: 8)
                            .cornerRadius(4)
                            .animation(.easeInOut(duration: 0.5), value: progress)
                    }
                }
                .frame(height: 8)
                
                if showPercentage {
                    Text("\(Int(progress * 100))%")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
    }
    
    /// Circular progress indicator
    public struct CircularProgressIndicator: View {
        let progress: Double
        let color: Color
        let size: CGFloat
        
        public init(progress: Double, color: Color = .blue, size: CGFloat = 60) {
            self.progress = min(max(progress, 0), 1)
            self.color = color
            self.size = size
        }
        
        public var body: some View {
            ZStack {
                Circle()
                    .stroke(Color(.systemGray5), lineWidth: 6)
                    .frame(width: size, height: size)
                
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(color, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                    .frame(width: size, height: size)
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 0.5), value: progress)
                
                Text("\(Int(progress * 100))%")
                    .font(.caption)
                    .fontWeight(.medium)
            }
        }
    }
    
    // MARK: - Full Screen Loading
    
    /// Full screen loading overlay
    public struct FullScreenLoader: View {
        let message: String
        let showBackground: Bool
        
        public init(message: String = "Loading...", showBackground: Bool = true) {
            self.message = message
            self.showBackground = showBackground
        }
        
        public var body: some View {
            ZStack {
                if showBackground {
                    Color.black.opacity(0.3)
                        .ignoresSafeArea()
                }
                
                VStack(spacing: 20) {
                    RotatingSpinner()
                    
                    Text(message)
                        .font(.headline)
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.center)
                }
                .padding(40)
                .background(Color(.systemBackground))
                .cornerRadius(16)
                .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 5)
            }
        }
    }
}

// MARK: - Supporting Views

/// Line chart skeleton
private struct LineChartSkeleton: View {
    var body: some View {
        Path { path in
            let width = 300.0
            let height = 150.0
            let points = stride(from: 0.0, to: width, by: width / 6).enumerated().map { index, x in
                CGPoint(
                    x: x,
                    y: height * 0.5 + sin(Double(index) * 0.5) * 30
                )
            }
            
            path.move(to: points[0])
            for point in points.dropFirst() {
                path.addLine(to: point)
            }
        }
        .stroke(Color(.systemGray4), style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))
        .opacity(0.5)
    }
}

/// Bar chart skeleton
private struct BarChartSkeleton: View {
    var body: some View {
        HStack(spacing: 8) {
            ForEach(0..<7, id: \.self) { _ in
                Rectangle()
                    .fill(Color(.systemGray4))
                    .frame(width: 30, height: CGFloat.random(in: 40...120))
                    .cornerRadius(4)
            }
        }
        .opacity(0.5)
    }
}

/// Pie chart skeleton
private struct PieChartSkeleton: View {
    var body: some View {
        Circle()
            .fill(Color(.systemGray4))
            .frame(width: 120, height: 120)
            .opacity(0.5)
    }
}

// MARK: - Shimmer Effect

/// Shimmer animation modifier
private struct ShimmerEffect: ViewModifier {
    @State private var phase: CGFloat = 0
    
    func body(content: Content) -> some View {
        content
            .overlay(
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.clear,
                        Color.white.opacity(0.3),
                        Color.clear
                    ]),
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .offset(x: -200 + phase * 400)
                .animation(.linear(duration: 1.5).repeatForever(autoreverses: false), value: phase)
                .onAppear {
                    phase = 1
                }
            )
            .clipped()
    }
}

extension View {
    func shimmer() -> some View {
        modifier(ShimmerEffect())
    }
}

// MARK: - Supporting Types

public enum ChartType {
    case line
    case bar
    case pie
}

// MARK: - Extensions

public extension LoadingStates {
    /// Create skeleton cards for health dashboard
    static func createDashboardSkeletons() -> [HealthDataSkeletonCard] {
        return [
            HealthDataSkeletonCard(title: "Heart Rate"),
            HealthDataSkeletonCard(title: "Steps"),
            HealthDataSkeletonCard(title: "Sleep"),
            HealthDataSkeletonCard(title: "Blood Pressure")
        ]
    }
    
    /// Create skeleton list for health data
    static func createListSkeletons(count: Int = 5) -> [HealthDataSkeletonListItem] {
        return Array(repeating: HealthDataSkeletonListItem(), count: count)
    }
} 