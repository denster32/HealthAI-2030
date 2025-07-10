import SwiftUI

// MARK: - Data Loading Animations
/// Comprehensive data loading animations for enhanced user experience
/// Provides smooth, engaging, and informative loading animations for data operations
public struct DataLoadingAnimations {
    
    // MARK: - Skeleton Loading Animation
    
    /// Skeleton loading animation for content placeholders
    public struct SkeletonLoadingAnimation: View {
        let type: SkeletonType
        let isAnimating: Bool
        @State private var shimmerOffset: CGFloat = -200
        
        public init(
            type: SkeletonType = .card,
            isAnimating: Bool = true
        ) {
            self.type = type
            self.isAnimating = isAnimating
        }
        
        public var body: some View {
            VStack(spacing: 12) {
                switch type {
                case .card:
                    skeletonCard
                case .list:
                    skeletonList
                case .profile:
                    skeletonProfile
                case .chart:
                    skeletonChart
                case .form:
                    skeletonForm
                }
            }
            .onAppear {
                if isAnimating {
                    startShimmerAnimation()
                }
            }
        }
        
        private var skeletonCard: some View {
            VStack(alignment: .leading, spacing: 12) {
                // Header
                HStack {
                    Circle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 40, height: 40)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Rectangle()
                            .fill(Color.gray.opacity(0.3))
                            .frame(height: 16)
                            .frame(width: 120)
                        
                        Rectangle()
                            .fill(Color.gray.opacity(0.3))
                            .frame(height: 12)
                            .frame(width: 80)
                    }
                    
                    Spacer()
                }
                
                // Content
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(height: 100)
                    .cornerRadius(8)
                
                // Footer
                HStack {
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(height: 12)
                        .frame(width: 60)
                    
                    Spacer()
                    
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(height: 12)
                        .frame(width: 40)
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemBackground))
                    .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
            )
            .overlay(
                shimmerOverlay
            )
        }
        
        private var skeletonList: some View {
            VStack(spacing: 16) {
                ForEach(0..<3, id: \.self) { _ in
                    HStack(spacing: 12) {
                        Circle()
                            .fill(Color.gray.opacity(0.3))
                            .frame(width: 50, height: 50)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Rectangle()
                                .fill(Color.gray.opacity(0.3))
                                .frame(height: 16)
                                .frame(width: 150)
                            
                            Rectangle()
                                .fill(Color.gray.opacity(0.3))
                                .frame(height: 12)
                                .frame(width: 100)
                        }
                        
                        Spacer()
                        
                        Rectangle()
                            .fill(Color.gray.opacity(0.3))
                            .frame(width: 60, height: 30)
                            .cornerRadius(6)
                    }
                    .padding(.horizontal, 16)
                }
            }
            .overlay(
                shimmerOverlay
            )
        }
        
        private var skeletonProfile: some View {
            VStack(spacing: 20) {
                // Avatar
                Circle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 100, height: 100)
                
                // Name
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(height: 24)
                    .frame(width: 150)
                
                // Bio
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(height: 16)
                    .frame(width: 200)
                
                // Stats
                HStack(spacing: 30) {
                    VStack(spacing: 8) {
                        Rectangle()
                            .fill(Color.gray.opacity(0.3))
                            .frame(height: 20)
                            .frame(width: 40)
                        
                        Rectangle()
                            .fill(Color.gray.opacity(0.3))
                            .frame(height: 12)
                            .frame(width: 60)
                    }
                    
                    VStack(spacing: 8) {
                        Rectangle()
                            .fill(Color.gray.opacity(0.3))
                            .frame(height: 20)
                            .frame(width: 40)
                        
                        Rectangle()
                            .fill(Color.gray.opacity(0.3))
                            .frame(height: 12)
                            .frame(width: 60)
                    }
                    
                    VStack(spacing: 8) {
                        Rectangle()
                            .fill(Color.gray.opacity(0.3))
                            .frame(height: 20)
                            .frame(width: 40)
                        
                        Rectangle()
                            .fill(Color.gray.opacity(0.3))
                            .frame(height: 12)
                            .frame(width: 60)
                    }
                }
            }
            .padding(20)
            .overlay(
                shimmerOverlay
            )
        }
        
        private var skeletonChart: some View {
            VStack(spacing: 16) {
                // Chart title
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(height: 20)
                    .frame(width: 120)
                
                // Chart area
                ZStack {
                    Rectangle()
                        .fill(Color.gray.opacity(0.1))
                        .frame(height: 200)
                        .cornerRadius(8)
                    
                    // Chart bars
                    HStack(alignment: .bottom, spacing: 8) {
                        ForEach(0..<7, id: \.self) { index in
                            Rectangle()
                                .fill(Color.gray.opacity(0.3))
                                .frame(width: 30, height: CGFloat.random(in: 50...150))
                                .cornerRadius(4)
                        }
                    }
                }
                
                // Legend
                HStack(spacing: 20) {
                    ForEach(0..<3, id: \.self) { _ in
                        HStack(spacing: 8) {
                            Circle()
                                .fill(Color.gray.opacity(0.3))
                                .frame(width: 12, height: 12)
                            
                            Rectangle()
                                .fill(Color.gray.opacity(0.3))
                                .frame(height: 12)
                                .frame(width: 60)
                        }
                    }
                }
            }
            .padding(16)
            .overlay(
                shimmerOverlay
            )
        }
        
        private var skeletonForm: some View {
            VStack(spacing: 20) {
                // Form title
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(height: 24)
                    .frame(width: 150)
                
                // Form fields
                VStack(spacing: 16) {
                    ForEach(0..<4, id: \.self) { _ in
                        VStack(alignment: .leading, spacing: 8) {
                            Rectangle()
                                .fill(Color.gray.opacity(0.3))
                                .frame(height: 16)
                                .frame(width: 80)
                            
                            Rectangle()
                                .fill(Color.gray.opacity(0.3))
                                .frame(height: 44)
                                .cornerRadius(8)
                        }
                    }
                }
                
                // Submit button
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(height: 50)
                    .cornerRadius(8)
            }
            .padding(20)
            .overlay(
                shimmerOverlay
            )
        }
        
        private var shimmerOverlay: some View {
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [Color.clear, Color.white.opacity(0.3), Color.clear],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .offset(x: shimmerOffset)
                .clipped()
        }
        
        private func startShimmerAnimation() {
            withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                shimmerOffset = 200
            }
        }
    }
    
    // MARK: - Data Fetch Animation
    
    /// Data fetch animation with progress indicators
    public struct DataFetchAnimation: View {
        let dataType: DataType
        let onComplete: () -> Void
        @State private var progress: Double = 0
        @State private var currentStep: Int = 0
        @State private var isComplete: Bool = false
        @State private var pulseScale: CGFloat = 1.0
        
        public init(
            dataType: DataType = .healthData,
            onComplete: @escaping () -> Void
        ) {
            self.dataType = dataType
            self.onComplete = onComplete
        }
        
        public var body: some View {
            VStack(spacing: 24) {
                // Icon with pulse
                ZStack {
                    Circle()
                        .fill(dataType.color.opacity(0.2))
                        .frame(width: 80, height: 80)
                        .scaleEffect(pulseScale)
                    
                    Image(systemName: dataType.icon)
                        .font(.system(size: 32, weight: .medium))
                        .foregroundColor(dataType.color)
                }
                
                // Progress indicator
                VStack(spacing: 12) {
                    ProgressView(value: progress)
                        .progressViewStyle(LinearProgressViewStyle(tint: dataType.color))
                        .frame(width: 200)
                    
                    Text("\(Int(progress * 100))%")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(dataType.color)
                }
                
                // Status message
                VStack(spacing: 8) {
                    Text(dataType.title)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.primary)
                    
                    Text(currentStep < dataType.steps.count ? dataType.steps[currentStep] : "Complete")
                        .font(.system(size: 14, weight: .regular))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                
                // Success indicator
                if isComplete {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 48, weight: .medium))
                        .foregroundColor(.green)
                        .transition(.scale.combined(with: .opacity))
                }
            }
            .padding(32)
            .onAppear {
                startDataFetch()
            }
        }
        
        private func startDataFetch() {
            // Start pulse animation
            withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
                pulseScale = 1.1
            }
            
            // Simulate data fetch steps
            for (index, _) in dataType.steps.enumerated() {
                DispatchQueue.main.asyncAfter(deadline: .now() + Double(index) * 1.0) {
                    withAnimation(.easeInOut(duration: 0.5)) {
                        currentStep = index
                        progress = Double(index + 1) / Double(dataType.steps.count)
                    }
                }
            }
            
            // Complete
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(dataType.steps.count) * 1.0) {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                    isComplete = true
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    onComplete()
                }
            }
        }
    }
    
    // MARK: - Sync Animation
    
    /// Data synchronization animation
    public struct SyncAnimation: View {
        let syncType: SyncType
        let onComplete: () -> Void
        @State private var rotation: Double = 0
        @State private var scale: CGFloat = 1.0
        @State private var opacity: Double = 1.0
        @State private var syncProgress: Double = 0
        @State private var isSyncing: Bool = false
        
        public init(
            syncType: SyncType = .healthKit,
            onComplete: @escaping () -> Void
        ) {
            self.syncType = syncType
            self.onComplete = onComplete
        }
        
        public var body: some View {
            VStack(spacing: 20) {
                // Sync icon
                ZStack {
                    Circle()
                        .fill(syncType.color.opacity(0.2))
                        .frame(width: 80, height: 80)
                    
                    Image(systemName: syncType.icon)
                        .font(.system(size: 32, weight: .medium))
                        .foregroundColor(syncType.color)
                        .rotationEffect(.degrees(rotation))
                        .scaleEffect(scale)
                        .opacity(opacity)
                }
                
                // Progress
                VStack(spacing: 8) {
                    ProgressView(value: syncProgress)
                        .progressViewStyle(LinearProgressViewStyle(tint: syncType.color))
                        .frame(width: 200)
                    
                    Text("\(Int(syncProgress * 100))%")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(syncType.color)
                }
                
                // Status
                Text(syncType.title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.primary)
                
                Text(isSyncing ? "Syncing..." : "Complete")
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(.secondary)
            }
            .padding(24)
            .onAppear {
                startSync()
            }
        }
        
        private func startSync() {
            isSyncing = true
            
            // Rotation animation
            withAnimation(.linear(duration: 2.0).repeatForever(autoreverses: false)) {
                rotation = 360
            }
            
            // Pulse animation
            withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
                scale = 1.1
            }
            
            // Progress animation
            withAnimation(.linear(duration: 3.0)) {
                syncProgress = 1.0
            }
            
            // Complete
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                    isSyncing = false
                    scale = 1.0
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    onComplete()
                }
            }
        }
    }
    
    // MARK: - Refresh Animation
    
    /// Pull-to-refresh animation
    public struct RefreshAnimation: View {
        let isRefreshing: Bool
        let onRefresh: () -> Void
        @State private var rotation: Double = 0
        @State private var scale: CGFloat = 1.0
        
        public init(
            isRefreshing: Bool = false,
            onRefresh: @escaping () -> Void
        ) {
            self.isRefreshing = isRefreshing
            self.onRefresh = onRefresh
        }
        
        public var body: some View {
            HStack(spacing: 12) {
                Image(systemName: "arrow.clockwise")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.blue)
                    .rotationEffect(.degrees(rotation))
                    .scaleEffect(scale)
                
                Text(isRefreshing ? "Refreshing..." : "Pull to refresh")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.blue)
            }
            .padding(.vertical, 8)
            .onAppear {
                if isRefreshing {
                    startRefreshAnimation()
                }
            }
            .onChange(of: isRefreshing) { refreshing in
                if refreshing {
                    startRefreshAnimation()
                } else {
                    stopRefreshAnimation()
                }
            }
        }
        
        private func startRefreshAnimation() {
            withAnimation(.linear(duration: 1.0).repeatForever(autoreverses: false)) {
                rotation = 360
            }
            
            withAnimation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true)) {
                scale = 1.2
            }
        }
        
        private func stopRefreshAnimation() {
            withAnimation(.easeInOut(duration: 0.3)) {
                rotation = 0
                scale = 1.0
            }
        }
    }
}

// MARK: - Supporting Types

enum SkeletonType {
    case card
    case list
    case profile
    case chart
    case form
}

enum DataType {
    case healthData
    case userProfile
    case analytics
    case settings
    
    var title: String {
        switch self {
        case .healthData: return "Loading Health Data"
        case .userProfile: return "Loading Profile"
        case .analytics: return "Loading Analytics"
        case .settings: return "Loading Settings"
        }
    }
    
    var icon: String {
        switch self {
        case .healthData: return "heart.fill"
        case .userProfile: return "person.fill"
        case .analytics: return "chart.bar.fill"
        case .settings: return "gear"
        }
    }
    
    var color: Color {
        switch self {
        case .healthData: return .red
        case .userProfile: return .blue
        case .analytics: return .green
        case .settings: return .gray
        }
    }
    
    var steps: [String] {
        switch self {
        case .healthData: return ["Connecting to devices", "Fetching data", "Processing metrics", "Updating dashboard"]
        case .userProfile: return ["Loading profile", "Fetching preferences", "Loading history", "Applying settings"]
        case .analytics: return ["Collecting data", "Analyzing trends", "Generating insights", "Preparing reports"]
        case .settings: return ["Loading configuration", "Applying preferences", "Validating settings", "Saving changes"]
        }
    }
}

enum SyncType {
    case healthKit
    case cloud
    case devices
    case backup
    
    var title: String {
        switch self {
        case .healthKit: return "HealthKit Sync"
        case .cloud: return "Cloud Sync"
        case .devices: return "Device Sync"
        case .backup: return "Backup Sync"
        }
    }
    
    var icon: String {
        switch self {
        case .healthKit: return "heart.fill"
        case .cloud: return "cloud.fill"
        case .devices: return "iphone"
        case .backup: return "externaldrive.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .healthKit: return .red
        case .cloud: return .blue
        case .devices: return .green
        case .backup: return .orange
        }
    }
}

// MARK: - Preview

struct DataLoadingAnimations_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 30) {
            SkeletonLoadingAnimation(type: .card)
            
            DataFetchAnimation(dataType: .healthData) {
                print("Data fetch complete")
            }
            
            SyncAnimation(syncType: .healthKit) {
                print("Sync complete")
            }
            
            RefreshAnimation(isRefreshing: true) {
                print("Refresh triggered")
            }
        }
        .padding()
        .previewLayout(.sizeThatFits)
    }
} 