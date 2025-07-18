import SwiftUI
import Charts

/// Comprehensive SwiftUI view for Multi-Platform Support
/// Provides interface for managing platforms, feature compatibility, and cross-platform sync
public struct MultiPlatformSupportView: View {
    @StateObject private var platformManager = MultiPlatformSupportManager.shared
    @State private var selectedTab = 0
    @State private var showingPlatformDetails = false
    @State private var selectedPlatform: MultiPlatformSupportManager.Platform?
    @State private var showingSyncView = false
    @State private var showingExportView = false
    @State private var searchText = ""
    @State private var selectedFeature: String?
    @State private var showingFeatureDetails = false
    
    public init() {}
    
    public var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header with current platform
                headerView
                
                // Tab selection
                tabSelectionView
                
                // Content based on selected tab
                TabView(selection: $selectedTab) {
                    platformsTabView
                        .tag(0)
                    
                    featuresTabView
                        .tag(1)
                    
                    syncTabView
                        .tag(2)
                    
                    optimizationsTabView
                        .tag(3)
                    
                    analyticsTabView
                        .tag(4)
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            }
            .navigationTitle("Multi-Platform")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button("Sync Platforms") {
                            showingSyncView = true
                        }
                        
                        Button("Export Data") {
                            showingExportView = true
                        }
                        
                        Button("Refresh") {
                            Task {
                                await platformManager.initialize()
                            }
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
        }
        .sheet(isPresented: $showingPlatformDetails) {
            if let platform = selectedPlatform {
                PlatformDetailsView(platform: platform)
            }
        }
        .sheet(isPresented: $showingSyncView) {
            CrossPlatformSyncView()
        }
        .sheet(isPresented: $showingExportView) {
            PlatformExportView()
        }
        .sheet(isPresented: $showingFeatureDetails) {
            if let feature = selectedFeature {
                FeatureDetailsView(featureName: feature)
            }
        }
        .onAppear {
            Task {
                await platformManager.initialize()
            }
        }
    }
    
    // MARK: - Header View
    
    private var headerView: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Current Platform")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    HStack {
                        Image(systemName: platformManager.currentPlatform.icon)
                            .foregroundColor(Color(platformManager.currentPlatform.color))
                        
                        Text(platformManager.currentPlatform.displayName)
                            .font(.headline)
                            .foregroundColor(.primary)
                    }
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Active Platforms")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("\(platformManager.platformStatus.values.filter { $0.isActive }.count)/\(MultiPlatformSupportManager.Platform.allCases.count)")
                        .font(.headline)
                        .foregroundColor(.primary)
                }
            }
            
            // Platform readiness progress
            ProgressView(value: Double(platformManager.platformStatus.values.filter { $0.isActive }.count), total: Double(MultiPlatformSupportManager.Platform.allCases.count))
                .progressViewStyle(LinearProgressViewStyle(tint: .green))
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
        .padding(.horizontal)
    }
    
    // MARK: - Tab Selection
    
    private var tabSelectionView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 0) {
                ForEach(["Platforms", "Features", "Sync", "Optimizations", "Analytics"], id: \.self) { tab in
                    Button(action: {
                        withAnimation {
                            selectedTab = ["Platforms", "Features", "Sync", "Optimizations", "Analytics"].firstIndex(of: tab) ?? 0
                        }
                    }) {
                        VStack(spacing: 4) {
                            Text(tab)
                                .font(.subheadline)
                                .fontWeight(selectedTab == ["Platforms", "Features", "Sync", "Optimizations", "Analytics"].firstIndex(of: tab) ? .semibold : .regular)
                                .foregroundColor(selectedTab == ["Platforms", "Features", "Sync", "Optimizations", "Analytics"].firstIndex(of: tab) ? .primary : .secondary)
                            
                            Rectangle()
                                .fill(selectedTab == ["Platforms", "Features", "Sync", "Optimizations", "Analytics"].firstIndex(of: tab) ? Color.blue : Color.clear)
                                .frame(height: 2)
                        }
                        .frame(width: 100)
                    }
                }
            }
            .padding(.horizontal)
        }
        .padding(.vertical, 8)
    }
    
    // MARK: - Platforms Tab
    
    private var platformsTabView: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(MultiPlatformSupportManager.Platform.allCases, id: \.self) { platform in
                    PlatformCardView(
                        platform: platform,
                        features: platformManager.platformFeatures[platform],
                        status: platformManager.platformStatus[platform]
                    ) {
                        selectedPlatform = platform
                        showingPlatformDetails = true
                    }
                }
            }
            .padding()
        }
    }
    
    // MARK: - Features Tab
    
    private var featuresTabView: some View {
        VStack(spacing: 16) {
            // Search bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                
                TextField("Search features...", text: $searchText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
            }
            .padding(.horizontal)
            
            // Features list
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(filteredFeatures, id: \.self) { feature in
                        FeatureCardView(
                            featureName: feature,
                            compatibility: platformManager.featureCompatibility[feature]
                        ) {
                            selectedFeature = feature
                            showingFeatureDetails = true
                        }
                    }
                }
                .padding()
            }
        }
    }
    
    private var filteredFeatures: [String] {
        let features = Array(platformManager.featureCompatibility.keys)
        if searchText.isEmpty {
            return features
        }
        return features.filter { $0.localizedCaseInsensitiveContains(searchText) }
    }
    
    // MARK: - Sync Tab
    
    private var syncTabView: some View {
        VStack(spacing: 16) {
            // Sync status
            VStack(spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Sync Status")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        Text(platformManager.crossPlatformSync.syncStatus.rawValue)
                            .font(.subheadline)
                            .foregroundColor(Color(platformManager.crossPlatformSync.syncStatus.color))
                    }
                    
                    Spacer()
                    
                    Button("Sync Now") {
                        Task {
                            await platformManager.syncAcrossPlatforms()
                        }
                    }
                    .buttonStyle(.borderedProminent)
                }
                
                if platformManager.crossPlatformSync.syncStatus == .syncing {
                    ProgressView(value: platformManager.crossPlatformSync.syncProgress)
                        .progressViewStyle(LinearProgressViewStyle(tint: .blue))
                }
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(radius: 2)
            
            // Devices list
            VStack(alignment: .leading, spacing: 12) {
                Text("Connected Devices")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(platformManager.crossPlatformSync.devices) { device in
                            DeviceCardView(device: device)
                        }
                    }
                }
            }
            .padding()
        }
        .padding(.horizontal)
    }
    
    // MARK: - Optimizations Tab
    
    private var optimizationsTabView: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(MultiPlatformSupportManager.Platform.allCases, id: \.self) { platform in
                    if let optimization = platformManager.platformOptimizations[platform] {
                        OptimizationCardView(optimization: optimization)
                    }
                }
            }
            .padding()
        }
    }
    
    // MARK: - Analytics Tab
    
    private var analyticsTabView: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Summary cards
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 16) {
                    let summary = platformManager.getCrossPlatformSummary()
                    
                    SummaryCardView(
                        title: "Total Devices",
                        value: "\(summary.totalDevices)",
                        icon: "iphone",
                        color: .blue
                    )
                    
                    SummaryCardView(
                        title: "Online Devices",
                        value: "\(summary.onlineDevices)",
                        icon: "wifi",
                        color: .green
                    )
                    
                    SummaryCardView(
                        title: "Active Platforms",
                        value: "\(summary.activePlatforms)",
                        icon: "square.grid.2x2",
                        color: .orange
                    )
                    
                    SummaryCardView(
                        title: "Supported Features",
                        value: "\(summary.fullySupportedFeatures)",
                        icon: "checkmark.circle",
                        color: .purple
                    )
                }
                
                // Platform compatibility chart
                PlatformCompatibilityChartView(featureCompatibility: platformManager.featureCompatibility)
                
                // Recent activity
                RecentPlatformActivityView(
                    platformStatus: platformManager.platformStatus,
                    crossPlatformSync: platformManager.crossPlatformSync
                )
            }
            .padding()
        }
    }
}

// MARK: - Supporting Views

struct PlatformCardView: View {
    let platform: MultiPlatformSupportManager.Platform
    let features: MultiPlatformSupportManager.PlatformFeatures?
    let status: MultiPlatformSupportManager.PlatformStatus?
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Image(systemName: platform.icon)
                                .foregroundColor(Color(platform.color))
                            
                            Text(platform.displayName)
                                .font(.headline)
                                .foregroundColor(.primary)
                        }
                        
                        if let status = status {
                            Text(status.isActive ? "Active" : "Inactive")
                                .font(.caption)
                                .foregroundColor(status.isActive ? .green : .red)
                        }
                    }
                    
                    Spacer()
                    
                    if let status = status {
                        VStack(alignment: .trailing, spacing: 4) {
                            Text("\(status.deviceCount)")
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            Text("Devices")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                if let features = features {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Supported Features")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text("\(features.supportedFeatures.count) features")
                            .font(.subheadline)
                            .foregroundColor(.primary)
                    }
                }
                
                if let status = status {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Performance")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Spacer()
                            
                            Text("\(Int(status.performanceScore * 100))%")
                                .font(.caption)
                                .fontWeight(.semibold)
                        }
                        
                        ProgressView(value: status.performanceScore)
                            .progressViewStyle(LinearProgressViewStyle(tint: .green))
                    }
                }
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(radius: 2)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct FeatureCardView: View {
    let featureName: String
    let compatibility: MultiPlatformSupportManager.FeatureCompatibility?
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(featureName)
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        if let compatibility = compatibility {
                            let fullySupported = compatibility.platforms.values.filter { $0 == .fullySupported }.count
                            let totalPlatforms = compatibility.platforms.count
                            Text("\(fullySupported)/\(totalPlatforms) platforms fully supported")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Spacer()
                    
                    if let compatibility = compatibility {
                        VStack(alignment: .trailing, spacing: 4) {
                            let supportRate = Double(compatibility.platforms.values.filter { $0 == .fullySupported }.count) / Double(compatibility.platforms.count)
                            Text("\(Int(supportRate * 100))%")
                                .font(.headline)
                                .foregroundColor(supportRate > 0.75 ? .green : supportRate > 0.5 ? .orange : .red)
                            
                            Text("Support")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                if let compatibility = compatibility {
                    // Platform compatibility indicators
                    HStack(spacing: 8) {
                        ForEach(MultiPlatformSupportManager.Platform.allCases, id: \.self) { platform in
                            if let status = compatibility.platforms[platform] {
                                Circle()
                                    .fill(Color(status.color))
                                    .frame(width: 12, height: 12)
                                    .overlay(
                                        Image(systemName: platform.icon)
                                            .font(.system(size: 6))
                                            .foregroundColor(.white)
                                    )
                            }
                        }
                        
                        Spacer()
                    }
                }
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(radius: 2)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct DeviceCardView: View {
    let device: MultiPlatformSupportManager.DeviceInfo
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(device.name)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text(device.platform.displayName)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    HStack {
                        Circle()
                            .fill(device.isOnline ? Color.green : Color.red)
                            .frame(width: 8, height: 8)
                        
                        Text(device.isOnline ? "Online" : "Offline")
                            .font(.caption)
                            .foregroundColor(device.isOnline ? .green : .red)
                    }
                    
                    Text(device.syncStatus.rawValue)
                        .font(.caption)
                        .foregroundColor(Color(device.syncStatus.color))
                }
            }
            
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Model")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text(device.model)
                        .font(.caption)
                        .foregroundColor(.primary)
                }
                
                HStack {
                    Text("OS Version")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text(device.osVersion)
                        .font(.caption)
                        .foregroundColor(.primary)
                }
                
                HStack {
                    Text("App Version")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text(device.appVersion)
                        .font(.caption)
                        .foregroundColor(.primary)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
}

struct OptimizationCardView: View {
    let optimization: MultiPlatformSupportManager.PlatformOptimization
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: optimization.platform.icon)
                    .foregroundColor(Color(optimization.platform.color))
                
                Text(optimization.platform.displayName)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Text("Last optimized: \(optimization.lastOptimized, style: .relative)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            // UI Optimizations
            VStack(alignment: .leading, spacing: 8) {
                Text("UI Optimizations")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                ForEach(optimization.uiOptimizations, id: \.name) { uiOpt in
                    HStack {
                        Image(systemName: uiOpt.isApplied ? "checkmark.circle.fill" : "circle")
                            .foregroundColor(uiOpt.isApplied ? .green : .gray)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(uiOpt.name)
                                .font(.caption)
                                .foregroundColor(.primary)
                            
                            Text(uiOpt.description)
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        Text(uiOpt.impact.rawValue)
                            .font(.caption2)
                            .foregroundColor(Color(uiOpt.impact.color))
                    }
                }
            }
            
            // Performance Optimizations
            VStack(alignment: .leading, spacing: 8) {
                Text("Performance Optimizations")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                ForEach(optimization.performanceOptimizations, id: \.name) { perfOpt in
                    HStack {
                        Image(systemName: perfOpt.isApplied ? "checkmark.circle.fill" : "circle")
                            .foregroundColor(perfOpt.isApplied ? .green : .gray)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(perfOpt.name)
                                .font(.caption)
                                .foregroundColor(.primary)
                            
                            Text(perfOpt.description)
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .trailing, spacing: 2) {
                            Text("+\(Int(perfOpt.performanceGain * 100))%")
                                .font(.caption2)
                                .foregroundColor(.green)
                            
                            Text("\(Int(perfOpt.memoryUsage * 100))% mem")
                                .font(.caption2)
                                .foregroundColor(.orange)
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
}

struct SummaryCardView: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            VStack(spacing: 4) {
                Text(value)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
}

struct PlatformCompatibilityChartView: View {
    let featureCompatibility: [String: MultiPlatformSupportManager.FeatureCompatibility]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Feature Compatibility")
                .font(.headline)
                .foregroundColor(.primary)
            
            if featureCompatibility.isEmpty {
                Text("No compatibility data available")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            } else {
                Chart(MultiPlatformSupportManager.Platform.allCases, id: \.self) { platform in
                    let fullySupported = featureCompatibility.values.filter { 
                        $0.platforms[platform] == .fullySupported 
                    }.count
                    
                    BarMark(
                        x: .value("Platform", platform.displayName),
                        y: .value("Features", fullySupported)
                    )
                    .foregroundStyle(Color(platform.color))
                }
                .frame(height: 200)
                .chartYAxis {
                    AxisMarks(position: .leading) {
                        AxisGridLine()
                        AxisTick()
                        AxisValueLabel()
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
}

struct RecentPlatformActivityView: View {
    let platformStatus: [MultiPlatformSupportManager.Platform: MultiPlatformSupportManager.PlatformStatus]
    let crossPlatformSync: MultiPlatformSupportManager.CrossPlatformSync
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Recent Activity")
                .font(.headline)
                .foregroundColor(.primary)
            
            VStack(spacing: 12) {
                ForEach(recentActivities.prefix(5), id: \.id) { activity in
                    HStack {
                        Image(systemName: activity.icon)
                            .foregroundColor(activity.color)
                            .frame(width: 20)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(activity.title)
                                .font(.subheadline)
                                .foregroundColor(.primary)
                            
                            Text(activity.description)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        Text(activity.timestamp, style: .relative)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
    
    private var recentActivities: [ActivityItem] {
        var activities: [ActivityItem] = []
        
        // Add platform status updates
        for (platform, status) in platformStatus {
            activities.append(ActivityItem(
                id: UUID(),
                title: "\(platform.displayName) Status",
                description: status.isActive ? "Platform active" : "Platform inactive",
                icon: platform.icon,
                color: status.isActive ? .green : .red,
                timestamp: status.lastActivity
            ))
        }
        
        // Add sync activities
        if let lastSync = crossPlatformSync.lastSyncDate {
            activities.append(ActivityItem(
                id: UUID(),
                title: "Cross-Platform Sync",
                description: "Data synchronized across \(crossPlatformSync.devices.count) devices",
                icon: "arrow.triangle.2.circlepath",
                color: .blue,
                timestamp: lastSync
            ))
        }
        
        return activities.sorted { $0.timestamp > $1.timestamp }
    }
}

struct ActivityItem {
    let id: UUID
    let title: String
    let description: String
    let icon: String
    let color: Color
    let timestamp: Date
}

// MARK: - Supporting Views (Placeholders)

struct PlatformDetailsView: View {
    let platform: MultiPlatformSupportManager.Platform
    
    var body: some View {
        Text("Platform Details for \(platform.displayName)")
            .padding()
    }
}

struct CrossPlatformSyncView: View {
    var body: some View {
        Text("Cross-Platform Sync")
            .padding()
    }
}

struct PlatformExportView: View {
    var body: some View {
        Text("Platform Export")
            .padding()
    }
}

struct FeatureDetailsView: View {
    let featureName: String
    
    var body: some View {
        Text("Feature Details for \(featureName)")
            .padding()
    }
}

#Preview {
    MultiPlatformSupportView()
} 