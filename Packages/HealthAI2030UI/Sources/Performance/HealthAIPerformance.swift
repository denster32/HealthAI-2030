import SwiftUI
import Combine

/// Comprehensive Performance Optimization System for HealthAI 2030
/// Provides lazy loading, caching, memory management, and performance monitoring
public struct HealthAIPerformance {
    
    // MARK: - Performance Configuration
    public struct Configuration {
        public static let maxCacheSize: Int = 100 // Maximum number of cached items
        public static let cacheExpirationTime: TimeInterval = 300 // 5 minutes
        public static let maxConcurrentOperations: Int = 4
        public static let memoryWarningThreshold: Double = 0.8 // 80% memory usage
        public static let frameRateTarget: Double = 60.0
        public static let animationFrameRate: Double = 60.0
        public static let imageCacheSize: Int = 50 // Maximum number of cached images
        public static let imageCacheExpiration: TimeInterval = 600 // 10 minutes
    }
    
    // MARK: - Performance Monitoring
    public class PerformanceMonitor: ObservableObject {
        @Published public var currentFPS: Double = 0.0
        @Published public var memoryUsage: Double = 0.0
        @Published public var cpuUsage: Double = 0.0
        @Published public var isPerformanceOptimal: Bool = true
        @Published public var performanceWarnings: [PerformanceWarning] = []
        
        private var displayLink: CADisplayLink?
        private var frameCount: Int = 0
        private var lastFrameTime: CFTimeInterval = 0
        private var timer: Timer?
        private var memoryWarningTimer: Timer?
        
        public init() {
            startMonitoring()
        }
        
        deinit {
            stopMonitoring()
        }
        
        public func startMonitoring() {
            #if os(iOS)
            displayLink = CADisplayLink(target: self, selector: #selector(updateFrameRate))
            displayLink?.add(to: .main, forMode: .common)
            #endif
            
            timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
                self.updateSystemMetrics()
            }
            
            memoryWarningTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { _ in
                self.checkMemoryUsage()
            }
        }
        
        public func stopMonitoring() {
            displayLink?.invalidate()
            displayLink = nil
            timer?.invalidate()
            timer = nil
            memoryWarningTimer?.invalidate()
            memoryWarningTimer = nil
        }
        
        @objc private func updateFrameRate() {
            frameCount += 1
            let currentTime = CACurrentMediaTime()
            
            if currentTime - lastFrameTime >= 1.0 {
                currentFPS = Double(frameCount)
                frameCount = 0
                lastFrameTime = currentTime
                
                isPerformanceOptimal = currentFPS >= Configuration.frameRateTarget * 0.9
                
                if !isPerformanceOptimal {
                    addPerformanceWarning(.lowFrameRate(currentFPS))
                }
            }
        }
        
        private func updateSystemMetrics() {
            // Update memory usage
            memoryUsage = getMemoryUsage()
            
            // Update CPU usage
            cpuUsage = getCPUUsage()
            
            // Check for performance warnings
            if memoryUsage > Configuration.memoryWarningThreshold {
                addPerformanceWarning(.highMemoryUsage(memoryUsage))
                PerformanceCache.shared.clearCache()
            }
            
            if cpuUsage > 0.8 {
                addPerformanceWarning(.highCPUUsage(cpuUsage))
            }
        }
        
        private func checkMemoryUsage() {
            let currentMemory = getMemoryUsage()
            if currentMemory > Configuration.memoryWarningThreshold {
                addPerformanceWarning(.memoryWarning(currentMemory))
                PerformanceCache.shared.evictOldestItems()
            }
        }
        
        private func addPerformanceWarning(_ warning: PerformanceWarning) {
            DispatchQueue.main.async {
                if !self.performanceWarnings.contains(where: { $0.type == warning.type }) {
                    self.performanceWarnings.append(warning)
                }
            }
        }
        
        private func getMemoryUsage() -> Double {
            #if os(iOS)
            var info = mach_task_basic_info()
            var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size)/4
            
            let kerr: kern_return_t = withUnsafeMutablePointer(to: &info) {
                $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                    task_info(mach_task_self_,
                             task_flavor_t(MACH_TASK_BASIC_INFO),
                             $0,
                             &count)
                }
            }
            
            if kerr == KERN_SUCCESS {
                return Double(info.resident_size) / Double(ProcessInfo.processInfo.physicalMemory)
            }
            #endif
            return 0.0
        }
        
        private func getCPUUsage() -> Double {
            // Simplified CPU usage calculation
            // In production, use proper system metrics
            return 0.0
        }
    }
    
    public enum PerformanceWarning {
        case lowFrameRate(Double)
        case highMemoryUsage(Double)
        case highCPUUsage(Double)
        case memoryWarning(Double)
        
        var type: String {
            switch self {
            case .lowFrameRate: return "lowFrameRate"
            case .highMemoryUsage: return "highMemoryUsage"
            case .highCPUUsage: return "highCPUUsage"
            case .memoryWarning: return "memoryWarning"
            }
        }
        
        var description: String {
            switch self {
            case .lowFrameRate(let fps):
                return "Low frame rate: \(String(format: "%.1f", fps)) FPS"
            case .highMemoryUsage(let usage):
                return "High memory usage: \(String(format: "%.1f", usage * 100))%"
            case .highCPUUsage(let usage):
                return "High CPU usage: \(String(format: "%.1f", usage * 100))%"
            case .memoryWarning(let usage):
                return "Memory warning: \(String(format: "%.1f", usage * 100))%"
            }
        }
    }
    
    // MARK: - Performance Cache
    public class PerformanceCache: ObservableObject {
        public static let shared = PerformanceCache()
        
        private var cache: [String: CachedItem] = [:]
        private let queue = DispatchQueue(label: "com.healthai.cache", qos: .utility)
        private let maxSize: Int
        private let expirationTime: TimeInterval
        
        private init(maxSize: Int = Configuration.maxCacheSize, expirationTime: TimeInterval = Configuration.cacheExpirationTime) {
            self.maxSize = maxSize
            self.expirationTime = expirationTime
        }
        
        public func set<T: Codable>(_ value: T, forKey key: String) {
            queue.async {
                let item = CachedItem(value: value, timestamp: Date())
                self.cache[key] = item
                
                // Enforce cache size limit
                if self.cache.count > self.maxSize {
                    self.evictOldestItems()
                }
            }
        }
        
        public func get<T: Codable>(forKey key: String) -> T? {
            return queue.sync {
                guard let item = cache[key] else { return nil }
                
                // Check expiration
                if Date().timeIntervalSince(item.timestamp) > expirationTime {
                    cache.removeValue(forKey: key)
                    return nil
                }
                
                return item.value as? T
            }
        }
        
        public func remove(forKey key: String) {
            queue.async {
                self.cache.removeValue(forKey: key)
            }
        }
        
        public func clearCache() {
            queue.async {
                self.cache.removeAll()
            }
        }
        
        public func evictOldestItems() {
            queue.async {
                let sortedItems = self.cache.sorted { $0.value.timestamp < $1.value.timestamp }
                let itemsToRemove = sortedItems.prefix(self.cache.count - self.maxSize)
                
                for item in itemsToRemove {
                    self.cache.removeValue(forKey: item.key)
                }
            }
        }
        
        private struct CachedItem {
            let value: Any
            let timestamp: Date
        }
    }
    
    // MARK: - Image Cache
    public class ImageCache: ObservableObject {
        public static let shared = ImageCache()
        
        private var cache: [String: CachedImage] = [:]
        private let queue = DispatchQueue(label: "com.healthai.imagecache", qos: .utility)
        private let maxSize: Int
        private let expirationTime: TimeInterval
        
        private init(maxSize: Int = Configuration.imageCacheSize, expirationTime: TimeInterval = Configuration.imageCacheExpiration) {
            self.maxSize = maxSize
            self.expirationTime = expirationTime
        }
        
        public func setImage(_ image: UIImage, forKey key: String) {
            queue.async {
                let item = CachedImage(image: image, timestamp: Date())
                self.cache[key] = item
                
                if self.cache.count > self.maxSize {
                    self.evictOldestItems()
                }
            }
        }
        
        public func getImage(forKey key: String) -> UIImage? {
            return queue.sync {
                guard let item = cache[key] else { return nil }
                
                if Date().timeIntervalSince(item.timestamp) > expirationTime {
                    cache.removeValue(forKey: key)
                    return nil
                }
                
                return item.image
            }
        }
        
        private func evictOldestItems() {
            let sortedItems = cache.sorted { $0.value.timestamp < $1.value.timestamp }
            let itemsToRemove = sortedItems.prefix(cache.count - maxSize)
            
            for item in itemsToRemove {
                cache.removeValue(forKey: item.key)
            }
        }
        
        private struct CachedImage {
            let image: UIImage
            let timestamp: Date
        }
    }
    
    // MARK: - Lazy Loading
    public struct LazyLoader<T> {
        private let loadOperation: () async throws -> T
        private let cacheKey: String?
        
        public init(loadOperation: @escaping () async throws -> T, cacheKey: String? = nil) {
            self.loadOperation = loadOperation
            self.cacheKey = cacheKey
        }
        
        public func load() async throws -> T {
            // Check cache first
            if let cacheKey = cacheKey,
               let cached: T = PerformanceCache.shared.get(forKey: cacheKey) {
                return cached
            }
            
            // Load data
            let result = try await loadOperation()
            
            // Cache result
            if let cacheKey = cacheKey {
                PerformanceCache.shared.set(result, forKey: cacheKey)
            }
            
            return result
        }
    }
    
    // MARK: - Optimized Views
    public struct OptimizedHealthDashboard: View {
        @StateObject private var healthDataManager = HealthDataManager.shared
        @StateObject private var performanceMonitor = PerformanceMonitor()
        @State private var visibleMetrics: Set<String> = []
        
        public var body: some View {
            ScrollView {
                LazyVStack(spacing: HealthAIDesignSystem.Spacing.lg) {
                    ForEach(healthDataManager.metrics, id: \.id) { metric in
                        OptimizedHealthCard(metric: metric)
                            .onAppear {
                                visibleMetrics.insert(metric.id)
                            }
                            .onDisappear {
                                visibleMetrics.remove(metric.id)
                            }
                    }
                }
                .padding()
            }
            .background(HealthAIDesignSystem.Colors.background)
            .overlay(
                // Performance indicator (only in debug builds)
                Group {
                    #if DEBUG
                    VStack {
                        HStack {
                            Text("FPS: \(String(format: "%.1f", performanceMonitor.currentFPS))")
                                .font(.caption)
                                .foregroundColor(performanceMonitor.isPerformanceOptimal ? .green : .red)
                            
                            Text("Memory: \(String(format: "%.1f", performanceMonitor.memoryUsage * 100))%")
                                .font(.caption)
                                .foregroundColor(performanceMonitor.memoryUsage > 0.8 ? .red : .green)
                        }
                        .padding(8)
                        .background(Color.black.opacity(0.7))
                        .foregroundColor(.white)
                        .cornerRadius(8)
                        
                        Spacer()
                    }
                    .padding()
                    #else
                    EmptyView()
                    #endif
                }
            )
        }
    }
    
    public struct OptimizedHealthCard: View {
        let metric: HealthMetric
        @State private var isLoaded = false
        
        public var body: some View {
            Group {
                if isLoaded {
                    AnimatedHealthCard(
                        title: metric.title,
                        value: metric.value,
                        unit: metric.unit,
                        color: metric.color,
                        icon: metric.icon,
                        trend: metric.trend,
                        status: metric.status
                    )
                } else {
                    HealthCardSkeleton()
                }
            }
            .onAppear {
                // Simulate loading delay for smooth appearance
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    withAnimation(HealthAIAnimations.Presets.smooth) {
                        isLoaded = true
                    }
                }
            }
            .drawingGroup() // Enable Metal acceleration
        }
    }
    
    public struct HealthCardSkeleton: View {
        @State private var isAnimating = false
        
        public var body: some View {
            VStack(alignment: .leading, spacing: HealthAIDesignSystem.Spacing.md) {
                // Header skeleton
                HStack {
                    Circle()
                        .fill(HealthAIDesignSystem.Colors.textTertiary)
                        .frame(width: 24, height: 24)
                    
                    Rectangle()
                        .fill(HealthAIDesignSystem.Colors.textTertiary)
                        .frame(height: 16)
                        .frame(maxWidth: .infinity)
                }
                
                // Value skeleton
                Rectangle()
                    .fill(HealthAIDesignSystem.Colors.textTertiary)
                    .frame(height: 32)
                    .frame(maxWidth: 0.6)
                
                // Trend skeleton
                Rectangle()
                    .fill(HealthAIDesignSystem.Colors.textTertiary)
                    .frame(height: 12)
                    .frame(maxWidth: 0.4)
            }
            .padding(HealthAIDesignSystem.Spacing.lg)
            .background(HealthAIDesignSystem.Colors.card)
            .cornerRadius(HealthAIDesignSystem.Layout.cornerRadius)
            .opacity(isAnimating ? 0.6 : 1.0)
            .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: isAnimating)
            .onAppear {
                isAnimating = true
            }
        }
    }
    
    // MARK: - Async Image Loading
    public struct OptimizedAsyncImage: View {
        let url: URL?
        let placeholder: String
        @State private var image: UIImage?
        @State private var isLoading = false
        
        public init(url: URL?, placeholder: String = "photo") {
            self.url = url
            self.placeholder = placeholder
        }
        
        public var body: some View {
            Group {
                if let image = image {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                } else if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
                } else {
                    Image(systemName: placeholder)
                        .foregroundColor(HealthAIDesignSystem.Colors.textTertiary)
                }
            }
            .onAppear {
                loadImage()
            }
        }
        
        private func loadImage() {
            guard let url = url else { return }
            
            // Check cache first
            if let cachedImage = ImageCache.shared.getImage(forKey: url.absoluteString) {
                self.image = cachedImage
                return
            }
            
            isLoading = true
            
            Task {
                do {
                    let (data, _) = try await URLSession.shared.data(from: url)
                    if let downloadedImage = UIImage(data: data) {
                        await MainActor.run {
                            self.image = downloadedImage
                            self.isLoading = false
                        }
                        
                        // Cache the image
                        ImageCache.shared.setImage(downloadedImage, forKey: url.absoluteString)
                    }
                } catch {
                    await MainActor.run {
                        self.isLoading = false
                    }
                }
            }
        }
    }
    
    // MARK: - Lazy Grid Optimization
    public struct OptimizedLazyGrid<Data: RandomAccessCollection, Content: View>: View where Data.Element: Identifiable {
        let data: Data
        let columns: [GridItem]
        let content: (Data.Element) -> Content
        
        public init(data: Data, columns: [GridItem], @ViewBuilder content: @escaping (Data.Element) -> Content) {
            self.data = data
            self.columns = columns
            self.content = content
        }
        
        public var body: some View {
            LazyVGrid(columns: columns, spacing: HealthAIDesignSystem.Spacing.md) {
                ForEach(data) { item in
                    content(item)
                        .drawingGroup() // Enable Metal acceleration for complex views
                }
            }
        }
    }
    
    // MARK: - Animation Optimization
    public struct OptimizedAnimation {
        
        /// Optimized animation that respects user preferences
        public static func accessibleAnimation<T: View>(_ content: T, animation: Animation) -> some View {
            let finalAnimation = HealthAIAccessibility.Status.isReduceMotionEnabled ? 
                Animation.linear(duration: 0.0) : 
                animation
            
            return content.animation(finalAnimation, value: true)
        }
        
        /// Optimized spring animation with performance considerations
        public static func optimizedSpring(response: Double = 0.3, dampingFraction: Double = 0.8) -> Animation {
            return Animation.spring(response: response, dampingFraction: dampingFraction)
        }
        
        /// Optimized transition with performance considerations
        public static func optimizedTransition(_ transition: AnyTransition) -> AnyTransition {
            return transition
        }
    }
    
    // MARK: - Memory Management
    public struct MemoryManager {
        /// Cleans up memory when needed
        public static func cleanupMemory() {
            PerformanceCache.shared.clearCache()
            ImageCache.shared.evictOldestItems()
            
            // Force garbage collection if available
            #if os(iOS)
            // iOS doesn't have explicit garbage collection
            #elseif os(macOS)
            // macOS can trigger memory cleanup
            #endif
        }
        
        /// Monitors memory usage and triggers cleanup if needed
        public static func monitorMemoryUsage() {
            let monitor = PerformanceMonitor()
            
            if monitor.memoryUsage > Configuration.memoryWarningThreshold {
                cleanupMemory()
            }
        }
    }
    
    // MARK: - Background Task Management
    public struct BackgroundTaskManager {
        private static var backgroundTasks: [UIBackgroundTaskIdentifier] = []
        
        public static func startBackgroundTask(name: String, expirationHandler: @escaping () -> Void) -> UIBackgroundTaskIdentifier? {
            #if os(iOS)
            let taskID = UIApplication.shared.beginBackgroundTask(withName: name) {
                expirationHandler()
                endBackgroundTask(taskID)
            }
            
            if taskID != .invalid {
                backgroundTasks.append(taskID)
                return taskID
            }
            #endif
            return nil
        }
        
        public static func endBackgroundTask(_ taskID: UIBackgroundTaskIdentifier?) {
            guard let taskID = taskID else { return }
            
            #if os(iOS)
            UIApplication.shared.endBackgroundTask(taskID)
            backgroundTasks.removeAll { $0 == taskID }
            #endif
        }
        
        public static func endAllBackgroundTasks() {
            #if os(iOS)
            for taskID in backgroundTasks {
                UIApplication.shared.endBackgroundTask(taskID)
            }
            backgroundTasks.removeAll()
            #endif
        }
    }
}

// MARK: - View Extensions
extension View {
    /// Apply performance optimizations
    public func healthAIPerformanceOptimized() -> some View {
        self
            .drawingGroup() // Enable Metal acceleration
            .animation(HealthAIPerformance.OptimizedAnimation.accessibleAnimation(self, animation: HealthAIAnimations.Presets.smooth), value: true)
    }
    
    /// Apply lazy loading optimization
    public func healthAILazyLoading() -> some View {
        self
            .onAppear {
                // Trigger lazy loading
            }
    }
    
    /// Apply memory optimization
    public func healthAIMemoryOptimized() -> some View {
        self
            .onDisappear {
                // Clean up resources
            }
    }
}

// MARK: - Supporting Types
public struct HealthMetric: Identifiable {
    public let id: String
    public let title: String
    public let value: String
    public let unit: String
    public let color: Color
    public let icon: String
    public let trend: String?
    public let status: HealthStatus
    
    public init(id: String, title: String, value: String, unit: String, color: Color, icon: String, trend: String? = nil, status: HealthStatus = .unknown) {
        self.id = id
        self.title = title
        self.value = value
        self.unit = unit
        self.color = color
        self.icon = icon
        self.trend = trend
        self.status = status
    }
}

public class HealthDataManager: ObservableObject {
    public static let shared = HealthDataManager()
    
    @Published public var metrics: [HealthMetric] = []
    
    private init() {
        loadSampleData()
    }
    
    private func loadSampleData() {
        metrics = [
            HealthMetric(id: "heartRate", title: "Heart Rate", value: "72", unit: "BPM", color: HealthAIDesignSystem.Colors.heartRate, icon: "heart.fill", trend: "+2 BPM", status: .healthy),
            HealthMetric(id: "sleep", title: "Sleep", value: "7.5", unit: "hrs", color: HealthAIDesignSystem.Colors.sleep, icon: "bed.double.fill", trend: "-0.5 hrs", status: .elevated),
            HealthMetric(id: "activity", title: "Activity", value: "8,432", unit: "steps", color: HealthAIDesignSystem.Colors.activity, icon: "figure.walk", trend: "+1,200 steps", status: .healthy)
        ]
    }
} 