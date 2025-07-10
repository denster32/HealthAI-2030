import SwiftUI

// MARK: - Pinch Zoom Animations
/// Comprehensive pinch zoom animations for enhanced user experience
/// Provides smooth, intuitive zoom interactions for images, charts, and content
public struct PinchZoomAnimations {
    
    // MARK: - Image Pinch Zoom Animation
    
    /// Pinch zoom animation for images with smooth scaling
    public struct ImagePinchZoomAnimation: View {
        let imageName: String
        let aspectRatio: CGFloat
        @State private var scale: CGFloat = 1.0
        @State private var lastScale: CGFloat = 1.0
        @State private var offset: CGSize = .zero
        @State private var lastOffset: CGSize = .zero
        @State private var isZoomed: Bool = false
        
        public init(
            imageName: String,
            aspectRatio: CGFloat = 1.0
        ) {
            self.imageName = imageName
            self.aspectRatio = aspectRatio
        }
        
        public var body: some View {
            GeometryReader { geometry in
                ZStack {
                    // Background
                    Color.black.opacity(isZoomed ? 0.8 : 0.0)
                        .ignoresSafeArea()
                        .animation(.easeInOut(duration: 0.3), value: isZoomed)
                    
                    // Image
                    Image(imageName)
                        .resizable()
                        .aspectRatio(aspectRatio, contentMode: .fit)
                        .scaleEffect(scale)
                        .offset(offset)
                        .gesture(
                            SimultaneousGesture(
                                MagnificationGesture()
                                    .onChanged { value in
                                        let delta = value / lastScale
                                        lastScale = value
                                        
                                        let newScale = scale * delta
                                        scale = min(max(newScale, 1.0), 4.0)
                                        
                                        isZoomed = scale > 1.0
                                    }
                                    .onEnded { _ in
                                        lastScale = 1.0
                                        
                                        // Snap to bounds
                                        if scale < 1.0 {
                                            withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                                                scale = 1.0
                                                offset = .zero
                                                isZoomed = false
                                            }
                                        }
                                    },
                                DragGesture()
                                    .onChanged { value in
                                        if scale > 1.0 {
                                            let delta = CGSize(
                                                width: value.translation.width - lastOffset.width,
                                                height: value.translation.height - lastOffset.height
                                            )
                                            lastOffset = value.translation
                                            
                                            let newOffset = CGSize(
                                                width: offset.width + delta.width,
                                                height: offset.height + delta.height
                                            )
                                            
                                            // Constrain to bounds
                                            let maxOffset = (scale - 1.0) * geometry.size.width / 2
                                            offset = CGSize(
                                                width: max(-maxOffset, min(maxOffset, newOffset.width)),
                                                height: max(-maxOffset, min(maxOffset, newOffset.height))
                                            )
                                        }
                                    }
                                    .onEnded { _ in
                                        lastOffset = .zero
                                    }
                            )
                        )
                        .onTapGesture(count: 2) {
                            withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                                if scale > 1.0 {
                                    scale = 1.0
                                    offset = .zero
                                    isZoomed = false
                                } else {
                                    scale = 2.0
                                    isZoomed = true
                                }
                            }
                        }
                    
                    // Zoom controls
                    if isZoomed {
                        VStack {
                            HStack {
                                Spacer()
                                
                                Button(action: {
                                    withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                                        scale = 1.0
                                        offset = .zero
                                        isZoomed = false
                                    }
                                }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .font(.system(size: 30, weight: .medium))
                                        .foregroundColor(.white)
                                        .background(Color.black.opacity(0.5))
                                        .clipShape(Circle())
                                }
                                .padding()
                            }
                            
                            Spacer()
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Chart Pinch Zoom Animation
    
    /// Pinch zoom animation for charts and data visualizations
    public struct ChartPinchZoomAnimation: View {
        let chartData: [ChartDataPoint]
        let chartType: ChartType
        @State private var scale: CGFloat = 1.0
        @State private var lastScale: CGFloat = 1.0
        @State private var offset: CGSize = .zero
        @State private var lastOffset: CGSize = .zero
        @State private var isZoomed: Bool = false
        
        public init(
            chartData: [ChartDataPoint],
            chartType: ChartType = .line
        ) {
            self.chartData = chartData
            self.chartType = chartType
        }
        
        public var body: some View {
            GeometryReader { geometry in
                ZStack {
                    // Chart background
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.systemGray6))
                        .overlay(
                            // Chart content
                            chartContent
                                .scaleEffect(scale)
                                .offset(offset)
                                .gesture(
                                    SimultaneousGesture(
                                        MagnificationGesture()
                                            .onChanged { value in
                                                let delta = value / lastScale
                                                lastScale = value
                                                
                                                let newScale = scale * delta
                                                scale = min(max(newScale, 0.5), 3.0)
                                                
                                                isZoomed = scale > 1.0
                                            }
                                            .onEnded { _ in
                                                lastScale = 1.0
                                                
                                                // Snap to bounds
                                                if scale < 0.5 {
                                                    withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                                                        scale = 0.5
                                                    }
                                                }
                                            },
                                        DragGesture()
                                            .onChanged { value in
                                                if scale > 1.0 {
                                                    let delta = CGSize(
                                                        width: value.translation.width - lastOffset.width,
                                                        height: value.translation.height - lastOffset.height
                                                    )
                                                    lastOffset = value.translation
                                                    
                                                    let newOffset = CGSize(
                                                        width: offset.width + delta.width,
                                                        height: offset.height + delta.height
                                                    )
                                                    
                                                    // Constrain to bounds
                                                    let maxOffset = (scale - 1.0) * geometry.size.width / 2
                                                    offset = CGSize(
                                                        width: max(-maxOffset, min(maxOffset, newOffset.width)),
                                                        height: max(-maxOffset, min(maxOffset, newOffset.height))
                                                    )
                                                }
                                            }
                                            .onEnded { _ in
                                                lastOffset = .zero
                                            }
                                    )
                                )
                        )
                    
                    // Zoom indicator
                    if isZoomed {
                        VStack {
                            HStack {
                                Spacer()
                                
                                Text("\(Int(scale * 100))%")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(Color.black.opacity(0.7))
                                    .cornerRadius(8)
                                    .padding()
                            }
                            
                            Spacer()
                        }
                    }
                }
            }
        }
        
        @ViewBuilder
        private var chartContent: some View {
            switch chartType {
            case .line:
                LineChartView(data: chartData)
            case .bar:
                BarChartView(data: chartData)
            case .pie:
                PieChartView(data: chartData)
            }
        }
    }
    
    // MARK: - Document Pinch Zoom Animation
    
    /// Pinch zoom animation for documents and text content
    public struct DocumentPinchZoomAnimation: View {
        let content: String
        let title: String
        @State private var scale: CGFloat = 1.0
        @State private var lastScale: CGFloat = 1.0
        @State private var offset: CGSize = .zero
        @State private var lastOffset: CGSize = .zero
        @State private var isZoomed: Bool = false
        
        public init(
            content: String,
            title: String
        ) {
            self.content = content
            self.title = title
        }
        
        public var body: some View {
            GeometryReader { geometry in
                ZStack {
                    // Background
                    Color(.systemBackground)
                        .ignoresSafeArea()
                    
                    ScrollView([.horizontal, .vertical]) {
                        VStack(alignment: .leading, spacing: 20) {
                            // Title
                            Text(title)
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(.primary)
                                .padding(.horizontal, 20)
                            
                            // Content
                            Text(content)
                                .font(.system(size: 16, weight: .regular))
                                .foregroundColor(.primary)
                                .lineSpacing(4)
                                .padding(.horizontal, 20)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .scaleEffect(scale)
                        .offset(offset)
                        .gesture(
                            SimultaneousGesture(
                                MagnificationGesture()
                                    .onChanged { value in
                                        let delta = value / lastScale
                                        lastScale = value
                                        
                                        let newScale = scale * delta
                                        scale = min(max(newScale, 0.5), 3.0)
                                        
                                        isZoomed = scale > 1.0
                                    }
                                    .onEnded { _ in
                                        lastScale = 1.0
                                    },
                                DragGesture()
                                    .onChanged { value in
                                        if scale > 1.0 {
                                            let delta = CGSize(
                                                width: value.translation.width - lastOffset.width,
                                                height: value.translation.height - lastOffset.height
                                            )
                                            lastOffset = value.translation
                                            
                                            let newOffset = CGSize(
                                                width: offset.width + delta.width,
                                                height: offset.height + delta.height
                                            )
                                            offset = newOffset
                                        }
                                    }
                                    .onEnded { _ in
                                        lastOffset = .zero
                                    }
                            )
                        )
                    }
                    
                    // Zoom controls
                    if isZoomed {
                        VStack {
                            HStack {
                                Spacer()
                                
                                VStack(spacing: 8) {
                                    Button(action: {
                                        withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                                            scale = min(scale + 0.25, 3.0)
                                        }
                                    }) {
                                        Image(systemName: "plus.circle.fill")
                                            .font(.system(size: 24, weight: .medium))
                                            .foregroundColor(.white)
                                            .background(Color.black.opacity(0.7))
                                            .clipShape(Circle())
                                    }
                                    
                                    Button(action: {
                                        withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                                            scale = max(scale - 0.25, 0.5)
                                        }
                                    }) {
                                        Image(systemName: "minus.circle.fill")
                                            .font(.system(size: 24, weight: .medium))
                                            .foregroundColor(.white)
                                            .background(Color.black.opacity(0.7))
                                            .clipShape(Circle())
                                    }
                                    
                                    Button(action: {
                                        withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                                            scale = 1.0
                                            offset = .zero
                                            isZoomed = false
                                        }
                                    }) {
                                        Image(systemName: "arrow.counterclockwise.circle.fill")
                                            .font(.system(size: 24, weight: .medium))
                                            .foregroundColor(.white)
                                            .background(Color.black.opacity(0.7))
                                            .clipShape(Circle())
                                    }
                                }
                                .padding()
                            }
                            
                            Spacer()
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Map Pinch Zoom Animation
    
    /// Pinch zoom animation for maps and location-based content
    public struct MapPinchZoomAnimation: View {
        let location: MapLocation
        let zoomLevel: Double
        @State private var scale: CGFloat = 1.0
        @State private var lastScale: CGFloat = 1.0
        @State private var offset: CGSize = .zero
        @State private var lastOffset: CGSize = .zero
        @State private var currentZoomLevel: Double
        
        public init(
            location: MapLocation,
            zoomLevel: Double = 1.0
        ) {
            self.location = location
            self.zoomLevel = zoomLevel
            self._currentZoomLevel = State(initialValue: zoomLevel)
        }
        
        public var body: some View {
            GeometryReader { geometry in
                ZStack {
                    // Map background
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.systemGray5))
                        .overlay(
                            // Map content
                            VStack {
                                Image(systemName: "map.fill")
                                    .font(.system(size: 40, weight: .medium))
                                    .foregroundColor(.blue)
                                
                                Text(location.name)
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(.primary)
                                
                                Text("Lat: \(location.latitude), Lon: \(location.longitude)")
                                    .font(.system(size: 14, weight: .regular))
                                    .foregroundColor(.secondary)
                            }
                            .scaleEffect(scale)
                            .offset(offset)
                            .gesture(
                                SimultaneousGesture(
                                    MagnificationGesture()
                                        .onChanged { value in
                                            let delta = value / lastScale
                                            lastScale = value
                                            
                                            let newScale = scale * delta
                                            scale = min(max(newScale, 0.5), 4.0)
                                            
                                            // Update zoom level
                                            currentZoomLevel = Double(scale) * zoomLevel
                                        }
                                        .onEnded { _ in
                                            lastScale = 1.0
                                        },
                                    DragGesture()
                                        .onChanged { value in
                                            if scale > 1.0 {
                                                let delta = CGSize(
                                                    width: value.translation.width - lastOffset.width,
                                                    height: value.translation.height - lastOffset.height
                                                )
                                                lastOffset = value.translation
                                                
                                                let newOffset = CGSize(
                                                    width: offset.width + delta.width,
                                                    height: offset.height + delta.height
                                                )
                                                
                                                // Constrain to bounds
                                                let maxOffset = (scale - 1.0) * geometry.size.width / 2
                                                offset = CGSize(
                                                    width: max(-maxOffset, min(maxOffset, newOffset.width)),
                                                    height: max(-maxOffset, min(maxOffset, newOffset.height))
                                                )
                                            }
                                        }
                                        .onEnded { _ in
                                            lastOffset = .zero
                                        }
                                )
                            )
                        )
                    
                    // Zoom level indicator
                    VStack {
                        HStack {
                            Spacer()
                            
                            Text("Zoom: \(Int(currentZoomLevel * 100))%")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.black.opacity(0.7))
                                .cornerRadius(6)
                                .padding()
                        }
                        
                        Spacer()
                    }
                }
            }
        }
    }
}

// MARK: - Supporting Types

struct ChartDataPoint {
    let label: String
    let value: Double
    let color: Color
    
    init(label: String, value: Double, color: Color = .blue) {
        self.label = label
        self.value = value
        self.color = color
    }
}

enum ChartType {
    case line
    case bar
    case pie
}

struct MapLocation {
    let name: String
    let latitude: Double
    let longitude: Double
    
    init(name: String, latitude: Double, longitude: Double) {
        self.name = name
        self.latitude = latitude
        self.longitude = longitude
    }
}

// MARK: - Chart View Components

struct LineChartView: View {
    let data: [ChartDataPoint]
    
    var body: some View {
        VStack {
            Text("Line Chart")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.primary)
            
            // Placeholder for line chart
            Rectangle()
                .fill(Color.blue.opacity(0.3))
                .frame(height: 100)
                .cornerRadius(8)
        }
        .padding()
    }
}

struct BarChartView: View {
    let data: [ChartDataPoint]
    
    var body: some View {
        VStack {
            Text("Bar Chart")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.primary)
            
            // Placeholder for bar chart
            Rectangle()
                .fill(Color.green.opacity(0.3))
                .frame(height: 100)
                .cornerRadius(8)
        }
        .padding()
    }
}

struct PieChartView: View {
    let data: [ChartDataPoint]
    
    var body: some View {
        VStack {
            Text("Pie Chart")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.primary)
            
            // Placeholder for pie chart
            Circle()
                .fill(Color.orange.opacity(0.3))
                .frame(width: 100, height: 100)
        }
        .padding()
    }
}

// MARK: - Preview

struct PinchZoomAnimations_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            ImagePinchZoomAnimation(imageName: "sample_image")
            
            ChartPinchZoomAnimation(
                chartData: [
                    ChartDataPoint(label: "Jan", value: 100),
                    ChartDataPoint(label: "Feb", value: 150),
                    ChartDataPoint(label: "Mar", value: 120)
                ],
                chartType: .line
            )
            
            DocumentPinchZoomAnimation(
                content: "This is a sample document content that can be zoomed and panned for better readability.",
                title: "Sample Document"
            )
            
            MapPinchZoomAnimation(
                location: MapLocation(name: "Sample Location", latitude: 37.7749, longitude: -122.4194)
            )
        }
        .padding()
        .previewLayout(.sizeThatFits)
    }
} 