import SwiftUI

/// Comprehensive real-time data synchronization view for HealthAI 2030
/// Provides complete interface for managing data sync, conflicts, and device connectivity
struct RealTimeDataSyncView: View {
    @StateObject private var syncManager = RealTimeDataSyncManager.shared
    @State private var selectedTab = 0
    @State private var showingConflictResolution = false
    @State private var showingExportSheet = false
    @State private var exportData: Data?
    @State private var selectedConflict: RealTimeDataSyncManager.SyncConflict?
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Header with sync status
                syncHeader
                
                // Tab selection
                Picker("Sync", selection: $selectedTab) {
                    Text("Overview").tag(0)
                    Text("Changes").tag(1)
                    Text("Conflicts").tag(2)
                    Text("Devices").tag(3)
                    Text("Settings").tag(4)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding()
                
                // Content based on selected tab
                TabView(selection: $selectedTab) {
                    overviewTab
                        .tag(0)
                    
                    changesTab
                        .tag(1)
                    
                    conflictsTab
                        .tag(2)
                    
                    devicesTab
                        .tag(3)
                    
                    settingsTab
                        .tag(4)
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            }
            .navigationTitle("Data Sync")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button("Start Sync") {
                            Task {
                                await syncManager.startSync()
                            }
                        }
                        Button("Export Data") {
                            exportSyncData()
                        }
                        Button(syncManager.syncStatus == .paused ? "Resume Sync" : "Pause Sync") {
                            if syncManager.syncStatus == .paused {
                                Task {
                                    await syncManager.resumeSync()
                                }
                            } else {
                                syncManager.pauseSync()
                            }
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
            .sheet(isPresented: $showingConflictResolution) {
                if let conflict = selectedConflict {
                    ConflictResolutionView(conflict: conflict)
                }
            }
            .sheet(isPresented: $showingExportSheet) {
                if let data = exportData {
                    ShareSheet(items: [data])
                }
            }
            .onAppear {
                Task {
                    await syncManager.initialize()
                }
            }
        }
    }
    
    // MARK: - Header
    
    private var syncHeader: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Real-Time Data Sync")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    if let lastSync = syncManager.lastSyncDate {
                        Text("Last sync: \(lastSync.formatted(date: .abbreviated, time: .shortened))")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                // Sync status badge
                HStack {
                    Circle()
                        .fill(Color(syncManager.syncStatus.color))
                        .frame(width: 12, height: 12)
                    
                    Text(syncManager.syncStatus.rawValue)
                        .font(.caption)
                        .fontWeight(.semibold)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color(.systemGray6))
                .cornerRadius(16)
            }
            
            // Network status and sync progress
            HStack(spacing: 20) {
                NetworkStatusCard()
                
                SyncProgressCard()
                
                DeviceCountCard()
            }
        }
        .padding()
        .background(Color(.systemGray6))
    }
    
    // MARK: - Overview Tab
    
    private var overviewTab: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Sync statistics
                SyncStatisticsCard()
                
                // Quick actions
                QuickActionsCard()
                
                // Recent activity
                RecentActivityCard()
                
                // Network information
                NetworkInfoCard()
            }
            .padding()
        }
    }
    
    // MARK: - Changes Tab
    
    private var changesTab: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                if syncManager.pendingChanges.isEmpty {
                    emptyStateView(
                        icon: "checkmark.circle.fill",
                        title: "No Pending Changes",
                        message: "All data is synchronized across devices."
                    )
                } else {
                    ForEach(syncManager.pendingChanges, id: \.id) { change in
                        SyncChangeCard(change: change)
                    }
                }
            }
            .padding()
        }
    }
    
    // MARK: - Conflicts Tab
    
    private var conflictsTab: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                if syncManager.conflicts.isEmpty {
                    emptyStateView(
                        icon: "checkmark.circle.fill",
                        title: "No Conflicts",
                        message: "All data changes are in sync."
                    )
                } else {
                    ForEach(syncManager.conflicts, id: \.id) { conflict in
                        SyncConflictCard(conflict: conflict) {
                            selectedConflict = conflict
                            showingConflictResolution = true
                        }
                    }
                }
            }
            .padding()
        }
    }
    
    // MARK: - Devices Tab
    
    private var devicesTab: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                if syncManager.connectedDevices.isEmpty {
                    emptyStateView(
                        icon: "iphone",
                        title: "No Connected Devices",
                        message: "No other devices are currently connected."
                    )
                } else {
                    ForEach(syncManager.connectedDevices, id: \.id) { device in
                        ConnectedDeviceCard(device: device)
                    }
                }
            }
            .padding()
        }
    }
    
    // MARK: - Settings Tab
    
    private var settingsTab: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Sync settings
                SyncSettingsCard()
                
                // Network settings
                NetworkSettingsCard()
                
                // Data management
                DataManagementCard()
                
                // Advanced settings
                AdvancedSettingsCard()
            }
            .padding()
        }
    }
    
    // MARK: - Helper Views
    
    private func emptyStateView(icon: String, title: String, message: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 60))
                .foregroundColor(.green)
            
            VStack(spacing: 8) {
                Text(title)
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text(message)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(40)
    }
    
    private func exportSyncData() {
        exportData = syncManager.exportSyncData()
        showingExportSheet = true
    }
}

// MARK: - Supporting Views

struct NetworkStatusCard: View {
    @StateObject private var syncManager = RealTimeDataSyncManager.shared
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: networkIcon)
                .font(.title2)
                .foregroundColor(networkColor)
            
            Text(networkStatusText)
                .font(.caption)
                .fontWeight(.medium)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(Color(.systemBackground))
        .cornerRadius(8)
    }
    
    private var networkIcon: String {
        switch syncManager.networkStatus {
        case .wifi: return "wifi"
        case .cellular: return "antenna.radiowaves.left.and.right"
        case .connected: return "network"
        case .disconnected: return "network.slash"
        case .unknown: return "questionmark.circle"
        }
    }
    
    private var networkColor: Color {
        switch syncManager.networkStatus {
        case .wifi, .cellular, .connected: return .green
        case .disconnected: return .red
        case .unknown: return .orange
        }
    }
    
    private var networkStatusText: String {
        switch syncManager.networkStatus {
        case .wifi: return "WiFi"
        case .cellular: return "Cellular"
        case .connected: return "Connected"
        case .disconnected: return "Offline"
        case .unknown: return "Unknown"
        }
    }
}

struct SyncProgressCard: View {
    @StateObject private var syncManager = RealTimeDataSyncManager.shared
    
    var body: some View {
        VStack(spacing: 4) {
            ProgressView(value: syncManager.syncProgress)
                .progressViewStyle(CircularProgressViewStyle())
                .scaleEffect(0.8)
            
            Text("\(Int(syncManager.syncProgress * 100))%")
                .font(.caption)
                .fontWeight(.medium)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(Color(.systemBackground))
        .cornerRadius(8)
    }
}

struct DeviceCountCard: View {
    @StateObject private var syncManager = RealTimeDataSyncManager.shared
    
    var body: some View {
        VStack(spacing: 4) {
            Text("\(syncManager.connectedDevices.count)")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.blue)
            
            Text("Devices")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(Color(.systemBackground))
        .cornerRadius(8)
    }
}

struct SyncStatisticsCard: View {
    @StateObject private var syncManager = RealTimeDataSyncManager.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Sync Statistics")
                .font(.headline)
                .fontWeight(.semibold)
            
            let stats = syncManager.getSyncStatistics()
            
            VStack(spacing: 12) {
                StatRow(label: "Total Changes", value: "\(stats.totalChanges)")
                StatRow(label: "Pending Changes", value: "\(stats.pendingChanges)", color: .orange)
                StatRow(label: "Total Conflicts", value: "\(stats.totalConflicts)")
                StatRow(label: "Pending Conflicts", value: "\(stats.pendingConflicts)", color: .red)
                StatRow(label: "Connected Devices", value: "\(stats.connectedDevices)")
                StatRow(label: "Sync Progress", value: "\(Int(stats.syncProgress * 100))%", color: .green)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }
}

struct StatRow: View {
    let label: String
    let value: String
    let color: Color?
    
    init(label: String, value: String, color: Color? = nil) {
        self.label = label
        self.value = value
        self.color = color
    }
    
    var body: some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(color)
        }
    }
}

struct QuickActionsCard: View {
    @StateObject private var syncManager = RealTimeDataSyncManager.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Quick Actions")
                .font(.headline)
                .fontWeight(.semibold)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                QuickActionButton(
                    icon: "arrow.clockwise",
                    title: "Sync Now",
                    color: .blue
                ) {
                    Task {
                        await syncManager.startSync()
                    }
                }
                
                QuickActionButton(
                    icon: "exclamationmark.triangle",
                    title: "Resolve Conflicts",
                    color: .orange
                ) {
                    // Show conflicts tab
                }
                
                QuickActionButton(
                    icon: "network",
                    title: "Check Network",
                    color: .green
                ) {
                    // Check network status
                }
                
                QuickActionButton(
                    icon: "gear",
                    title: "Settings",
                    color: .purple
                ) {
                    // Show settings
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }
}

struct QuickActionButton: View {
    let icon: String
    let title: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(Color(.systemGray6))
            .cornerRadius(8)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct RecentActivityCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Recent Activity")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: 12) {
                ActivityRow(
                    icon: "checkmark.circle.fill",
                    title: "Sync completed",
                    time: "2 minutes ago",
                    color: .green
                )
                
                ActivityRow(
                    icon: "exclamationmark.triangle.fill",
                    title: "Conflict detected",
                    time: "5 minutes ago",
                    color: .orange
                )
                
                ActivityRow(
                    icon: "iphone",
                    title: "Device connected",
                    time: "10 minutes ago",
                    color: .blue
                )
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }
}

struct ActivityRow: View {
    let icon: String
    let title: String
    let time: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(color)
                .frame(width: 20)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                
                Text(time)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
    }
}

struct NetworkInfoCard: View {
    @StateObject private var syncManager = RealTimeDataSyncManager.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Network Information")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: 8) {
                InfoRow(label: "Status", value: syncManager.networkStatus.rawValue)
                InfoRow(label: "Connection", value: syncManager.networkStatus.isConnected ? "Available" : "Unavailable")
                InfoRow(label: "Auto-sync", value: "Enabled")
                InfoRow(label: "Sync interval", value: "5 minutes")
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }
}

struct InfoRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
        }
    }
}

struct SyncChangeCard: View {
    let change: RealTimeDataSyncManager.SyncChange
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: operationIcon)
                    .foregroundColor(operationColor)
                    .frame(width: 20)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(change.operation.description)
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Text(change.entityType)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                PriorityBadge(priority: change.priority)
            }
            
            Text("ID: \(change.entityId)")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text("Device: \(change.deviceId)")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text("Time: \(change.timestamp.formatted(date: .abbreviated, time: .shortened))")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }
    
    private var operationIcon: String {
        switch change.operation {
        case .create: return "plus.circle.fill"
        case .update: return "pencil.circle.fill"
        case .delete: return "minus.circle.fill"
        case .merge: return "arrow.triangle.merge"
        }
    }
    
    private var operationColor: Color {
        switch change.operation {
        case .create: return .green
        case .update: return .blue
        case .delete: return .red
        case .merge: return .purple
        }
    }
}

struct PriorityBadge: View {
    let priority: RealTimeDataSyncManager.SyncPriority
    
    var body: some View {
        Text(priority.rawValue)
            .font(.caption2)
            .fontWeight(.semibold)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(priorityColor.opacity(0.2))
            .foregroundColor(priorityColor)
            .cornerRadius(8)
    }
    
    private var priorityColor: Color {
        switch priority {
        case .low: return .gray
        case .normal: return .blue
        case .high: return .orange
        case .critical: return .red
        }
    }
}

struct SyncConflictCard: View {
    let conflict: RealTimeDataSyncManager.SyncConflict
    let onResolve: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.orange)
                    .frame(width: 20)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(conflict.conflictType.rawValue)
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Text(conflict.entityType)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                if !conflict.isResolved {
                    Button("Resolve") {
                        onResolve()
                    }
                    .font(.caption)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.orange)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                } else {
                    Text("Resolved")
                        .font(.caption)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.green.opacity(0.2))
                        .foregroundColor(.green)
                        .cornerRadius(8)
                }
            }
            
            Text("ID: \(conflict.entityId)")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text("Local: \(conflict.localChange.operation.description)")
                .font(.caption)
                .foregroundColor(.blue)
            
            Text("Remote: \(conflict.remoteChange.operation.description)")
                .font(.caption)
                .foregroundColor(.orange)
            
            Text("Time: \(conflict.timestamp.formatted(date: .abbreviated, time: .shortened))")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }
}

struct ConnectedDeviceCard: View {
    let device: RealTimeDataSyncManager.ConnectedDevice
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: device.deviceType.icon)
                .font(.title2)
                .foregroundColor(.blue)
                .frame(width: 40)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(device.deviceName)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(device.deviceType.rawValue)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text("Last seen: \(device.lastSeen.formatted(date: .abbreviated, time: .shortened))")
                    .font(.caption2)
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
                        .foregroundColor(.secondary)
                }
                
                Text(device.syncStatus.rawValue)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }
}

// MARK: - Settings Views

struct SyncSettingsCard: View {
    @State private var autoSync = true
    @State private var syncInterval = 5
    @State private var syncOnWiFiOnly = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Sync Settings")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: 12) {
                Toggle("Auto-sync", isOn: $autoSync)
                
                HStack {
                    Text("Sync interval")
                    Spacer()
                    Picker("Interval", selection: $syncInterval) {
                        Text("1 min").tag(1)
                        Text("5 min").tag(5)
                        Text("15 min").tag(15)
                        Text("30 min").tag(30)
                    }
                    .pickerStyle(MenuPickerStyle())
                }
                
                Toggle("WiFi only", isOn: $syncOnWiFiOnly)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }
}

struct NetworkSettingsCard: View {
    @State private var allowCellular = true
    @State private var retryOnFailure = true
    @State private var maxRetries = 3
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Network Settings")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: 12) {
                Toggle("Allow cellular data", isOn: $allowCellular)
                Toggle("Retry on failure", isOn: $retryOnFailure)
                
                HStack {
                    Text("Max retries")
                    Spacer()
                    Picker("Retries", selection: $maxRetries) {
                        Text("1").tag(1)
                        Text("3").tag(3)
                        Text("5").tag(5)
                        Text("10").tag(10)
                    }
                    .pickerStyle(MenuPickerStyle())
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }
}

struct DataManagementCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Data Management")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: 12) {
                Button("Clear pending changes") {
                    // Implementation
                }
                .foregroundColor(.red)
                
                Button("Clear conflicts") {
                    // Implementation
                }
                .foregroundColor(.red)
                
                Button("Export sync data") {
                    // Implementation
                }
                .foregroundColor(.blue)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }
}

struct AdvancedSettingsCard: View {
    @State private var debugMode = false
    @State private var verboseLogging = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Advanced Settings")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: 12) {
                Toggle("Debug mode", isOn: $debugMode)
                Toggle("Verbose logging", isOn: $verboseLogging)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }
}

// MARK: - Sheet Views

struct ConflictResolutionView: View {
    let conflict: RealTimeDataSyncManager.SyncConflict
    @Environment(\.dismiss) private var dismiss
    @StateObject private var syncManager = RealTimeDataSyncManager.shared
    @State private var selectedResolution: RealTimeDataSyncManager.ConflictResolution = .useLocal
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Conflict details
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Conflict Details")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        Text("Type: \(conflict.conflictType.rawValue)")
                            .font(.subheadline)
                        
                        Text("Entity: \(conflict.entityType)")
                            .font(.subheadline)
                        
                        Text("ID: \(conflict.entityId)")
                            .font(.subheadline)
                    }
                    
                    // Resolution options
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Resolution Options")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        ForEach(RealTimeDataSyncManager.ConflictResolution.allCases, id: \.self) { resolution in
                            HStack {
                                RadioButton(
                                    isSelected: selectedResolution == resolution,
                                    action: { selectedResolution = resolution }
                                )
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(resolution.rawValue)
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                    
                                    Text(resolution.description)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                            }
                            .padding(.vertical, 4)
                        }
                    }
                    
                    // Action buttons
                    VStack(spacing: 12) {
                        Button("Resolve Conflict") {
                            Task {
                                await syncManager.resolveConflict(conflict, resolution: selectedResolution)
                                dismiss()
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .frame(maxWidth: .infinity)
                        
                        Button("Cancel") {
                            dismiss()
                        }
                        .buttonStyle(.bordered)
                        .frame(maxWidth: .infinity)
                    }
                }
                .padding()
            }
            .navigationTitle("Resolve Conflict")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

struct RadioButton: View {
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Image(systemName: isSelected ? "largecircle.fill.circle" : "circle")
                .foregroundColor(isSelected ? .blue : .gray)
                .font(.title3)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// MARK: - Preview

struct RealTimeDataSyncView_Previews: PreviewProvider {
    static var previews: some View {
        RealTimeDataSyncView()
    }
} 