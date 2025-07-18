import SwiftUI
import Charts

/// Advanced Health Device Integration & IoT Management Dashboard
/// Provides comprehensive device management, sensor fusion, IoT control, and real-time monitoring
@available(iOS 18.0, macOS 15.0, *)
public struct AdvancedHealthDeviceIntegrationDashboardView: View {
    
    // MARK: - Environment
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    
    // MARK: - State
    @StateObject private var viewModel = AdvancedHealthDeviceIntegrationViewModel()
    @State private var selectedTab = 0
    @State private var showingDeviceScan = false
    @State private var showingIoTDevice = false
    @State private var showingSensorFusion = false
    @State private var showingDeviceDetails = false
    @State private var selectedDevice: HealthDevice?
    @State private var selectedIoTDevice: IoTDevice?
    
    // MARK: - Body
    public var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header
                headerView
                
                // Tab Content
                TabView(selection: $selectedTab) {
                    // Devices Tab
                    devicesTabView
                        .tag(0)
                    
                    // IoT Tab
                    iotTabView
                        .tag(1)
                    
                    // Sensor Fusion Tab
                    sensorFusionTabView
                        .tag(2)
                    
                    // Analytics Tab
                    analyticsTabView
                        .tag(3)
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            }
            .background(backgroundColor)
            .navigationBarHidden(true)
        }
        .onAppear {
            viewModel.loadData()
        }
        .sheet(isPresented: $showingDeviceScan) {
            DeviceScanView(viewModel: viewModel)
        }
        .sheet(isPresented: $showingIoTDevice) {
            IoTDeviceView(viewModel: viewModel)
        }
        .sheet(isPresented: $showingSensorFusion) {
            SensorFusionView(viewModel: viewModel)
        }
        .sheet(isPresented: $showingDeviceDetails) {
            if let device = selectedDevice {
                DeviceDetailsView(device: device, viewModel: viewModel)
            }
        }
    }
    
    // MARK: - Header View
    private var headerView: some View {
        VStack(spacing: 16) {
            HStack {
                Button(action: { dismiss() }) {
                    Image(systemName: "chevron.left")
                        .font(.title2)
                        .foregroundColor(.primary)
                }
                
                Spacer()
                
                Text("Device Integration")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Spacer()
                
                Button(action: { viewModel.refreshData() }) {
                    Image(systemName: "arrow.clockwise")
                        .font(.title2)
                        .foregroundColor(.primary)
                }
            }
            .padding(.horizontal)
            
            // Tab Indicators
            HStack(spacing: 0) {
                ForEach(0..<4) { index in
                    Button(action: { selectedTab = index }) {
                        VStack(spacing: 4) {
                            Text(tabTitle(for: index))
                                .font(.caption)
                                .fontWeight(selectedTab == index ? .semibold : .regular)
                                .foregroundColor(selectedTab == index ? .primary : .secondary)
                            
                            Rectangle()
                                .fill(selectedTab == index ? Color.accentColor : Color.clear)
                                .frame(height: 2)
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .padding(.horizontal)
        }
        .padding(.vertical)
        .background(headerBackgroundColor)
    }
    
    // MARK: - Devices Tab View
    private var devicesTabView: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                // Integration Status
                integrationStatusCard
                
                // Connected Devices
                connectedDevicesCard
                
                // Available Devices
                availableDevicesCard
                
                // Device Alerts
                deviceAlertsCard
            }
            .padding()
        }
    }
    
    // MARK: - IoT Tab View
    private var iotTabView: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                // IoT Overview
                iotOverviewCard
                
                // IoT Devices by Category
                iotDevicesByCategoryCard
                
                // IoT Analytics
                iotAnalyticsCard
            }
            .padding()
        }
    }
    
    // MARK: - Sensor Fusion Tab View
    private var sensorFusionTabView: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                // Sensor Fusion Status
                sensorFusionStatusCard
                
                // Sensor Data
                sensorDataCard
                
                // Fusion Insights
                fusionInsightsCard
                
                // Sensor Analytics
                sensorAnalyticsCard
            }
            .padding()
        }
    }
    
    // MARK: - Analytics Tab View
    private var analyticsTabView: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                // Device Analytics
                deviceAnalyticsCard
                
                // Performance Metrics
                performanceMetricsCard
                
                // Integration History
                integrationHistoryCard
            }
            .padding()
        }
    }
    
    // MARK: - Integration Status Card
    private var integrationStatusCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Integration Status")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Button(action: {
                    if viewModel.isIntegrationActive {
                        Task { await viewModel.stopDeviceIntegration() }
                    } else {
                        Task { await viewModel.startDeviceIntegration() }
                    }
                }) {
                    Text(viewModel.isIntegrationActive ? "Stop" : "Start")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(viewModel.isIntegrationActive ? Color.red : Color.green)
                        .cornerRadius(8)
                }
            }
            
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Connected Devices")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("\(viewModel.connectedDevices.count)")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Available Devices")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("\(viewModel.availableDevices.count)")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                }
            }
            
            if viewModel.isIntegrationActive {
                ProgressView(value: viewModel.integrationProgress)
                    .progressViewStyle(LinearProgressViewStyle())
                    .accentColor(.green)
            }
            
            if let error = viewModel.lastError {
                Text(error)
                    .font(.caption)
                    .foregroundColor(.red)
                    .padding(.top, 4)
            }
        }
        .padding()
        .background(cardBackgroundColor)
        .cornerRadius(12)
    }
    
    // MARK: - Connected Devices Card
    private var connectedDevicesCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Connected Devices")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Button(action: { showingDeviceScan = true }) {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                        .foregroundColor(.accentColor)
                }
            }
            
            if viewModel.connectedDevices.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "devices")
                        .font(.title)
                        .foregroundColor(.secondary)
                    
                    Text("No devices connected")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Button("Scan for Devices") {
                        showingDeviceScan = true
                    }
                    .font(.caption)
                    .foregroundColor(.accentColor)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
            } else {
                LazyVStack(spacing: 8) {
                    ForEach(viewModel.connectedDevices.prefix(3)) { device in
                        DeviceRowView(device: device) {
                            selectedDevice = device
                            showingDeviceDetails = true
                        }
                    }
                    
                    if viewModel.connectedDevices.count > 3 {
                        Button("View All \(viewModel.connectedDevices.count) Devices") {
                            selectedTab = 0
                        }
                        .font(.caption)
                        .foregroundColor(.accentColor)
                    }
                }
            }
        }
        .padding()
        .background(cardBackgroundColor)
        .cornerRadius(12)
    }
    
    // MARK: - Available Devices Card
    private var availableDevicesCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Available Devices")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Button(action: { viewModel.scanForDevices() }) {
                    Image(systemName: "magnifyingglass")
                        .font(.title2)
                        .foregroundColor(.accentColor)
                }
            }
            
            if viewModel.availableDevices.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "antenna.radiowaves.left.and.right")
                        .font(.title)
                        .foregroundColor(.secondary)
                    
                    Text("No devices found")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Button("Scan Again") {
                        viewModel.scanForDevices()
                    }
                    .font(.caption)
                    .foregroundColor(.accentColor)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
            } else {
                LazyVStack(spacing: 8) {
                    ForEach(viewModel.availableDevices.prefix(3)) { device in
                        AvailableDeviceRowView(device: device) {
                            Task { await viewModel.connectToDevice(device) }
                        }
                    }
                    
                    if viewModel.availableDevices.count > 3 {
                        Button("View All \(viewModel.availableDevices.count) Devices") {
                            selectedTab = 0
                        }
                        .font(.caption)
                        .foregroundColor(.accentColor)
                    }
                }
            }
        }
        .padding()
        .background(cardBackgroundColor)
        .cornerRadius(12)
    }
    
    // MARK: - Device Alerts Card
    private var deviceAlertsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Device Alerts")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                if !viewModel.deviceAlerts.isEmpty {
                    Text("\(viewModel.deviceAlerts.count)")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.red)
                        .cornerRadius(8)
                }
            }
            
            if viewModel.deviceAlerts.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "checkmark.circle")
                        .font(.title)
                        .foregroundColor(.green)
                    
                    Text("No alerts")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
            } else {
                LazyVStack(spacing: 8) {
                    ForEach(viewModel.deviceAlerts.prefix(3)) { alert in
                        AlertRowView(alert: alert)
                    }
                    
                    if viewModel.deviceAlerts.count > 3 {
                        Button("View All \(viewModel.deviceAlerts.count) Alerts") {
                            selectedTab = 0
                        }
                        .font(.caption)
                        .foregroundColor(.accentColor)
                    }
                }
            }
        }
        .padding()
        .background(cardBackgroundColor)
        .cornerRadius(12)
    }
    
    // MARK: - IoT Overview Card
    private var iotOverviewCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("IoT Overview")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Button(action: { showingIoTDevice = true }) {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                        .foregroundColor(.accentColor)
                }
            }
            
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Total IoT Devices")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("\(viewModel.iotDevices.count)")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Online Devices")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("\(viewModel.iotDevices.filter { $0.status == .online }.count)")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.green)
                }
            }
            
            // IoT Categories Chart
            if !viewModel.iotDevices.isEmpty {
                Chart {
                    ForEach(IoTCategory.allCases, id: \.self) { category in
                        let count = viewModel.iotDevices.filter { $0.category == category }.count
                        if count > 0 {
                            BarMark(
                                x: .value("Category", category.rawValue.capitalized),
                                y: .value("Count", count)
                            )
                            .foregroundStyle(Color.accentColor.gradient)
                        }
                    }
                }
                .frame(height: 120)
            }
        }
        .padding()
        .background(cardBackgroundColor)
        .cornerRadius(12)
    }
    
    // MARK: - IoT Devices by Category Card
    private var iotDevicesByCategoryCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("IoT Devices by Category")
                .font(.headline)
                .fontWeight(.semibold)
            
            LazyVStack(spacing: 8) {
                ForEach(IoTCategory.allCases, id: \.self) { category in
                    let devices = viewModel.iotDevices.filter { $0.category == category }
                    if !devices.isEmpty {
                        IoTCategoryRowView(category: category, devices: devices)
                    }
                }
            }
        }
        .padding()
        .background(cardBackgroundColor)
        .cornerRadius(12)
    }
    
    // MARK: - IoT Analytics Card
    private var iotAnalyticsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("IoT Analytics")
                .font(.headline)
                .fontWeight(.semibold)
            
            if viewModel.iotDevices.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "chart.bar")
                        .font(.title)
                        .foregroundColor(.secondary)
                    
                    Text("No IoT data available")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
            } else {
                VStack(spacing: 12) {
                    // Device Status Distribution
                    HStack {
                        Text("Device Status")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        Spacer()
                        
                        VStack(alignment: .trailing, spacing: 4) {
                            Text("Online: \(viewModel.iotDevices.filter { $0.status == .online }.count)")
                                .font(.caption)
                                .foregroundColor(.green)
                            
                            Text("Offline: \(viewModel.iotDevices.filter { $0.status == .offline }.count)")
                                .font(.caption)
                                .foregroundColor(.red)
                        }
                    }
                    
                    // Category Distribution
                    HStack {
                        Text("Category Distribution")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        Spacer()
                        
                        VStack(alignment: .trailing, spacing: 4) {
                            ForEach(IoTCategory.allCases.prefix(3), id: \.self) { category in
                                let count = viewModel.iotDevices.filter { $0.category == category }.count
                                if count > 0 {
                                    Text("\(category.rawValue.capitalized): \(count)")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                    }
                }
            }
        }
        .padding()
        .background(cardBackgroundColor)
        .cornerRadius(12)
    }
    
    // MARK: - Sensor Fusion Status Card
    private var sensorFusionStatusCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Sensor Fusion Status")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Button(action: { showingSensorFusion = true }) {
                    Image(systemName: "waveform.path.ecg")
                        .font(.title2)
                        .foregroundColor(.accentColor)
                }
            }
            
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Active Sensors")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("\(viewModel.sensorFusion.insights.count)")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Last Fusion")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(viewModel.sensorFusion.timestamp, style: .relative)
                        .font(.caption)
                        .foregroundColor(.primary)
                }
            }
            
            if !viewModel.sensorFusion.insights.isEmpty {
                Button("Perform Fusion Analysis") {
                    Task { await viewModel.performSensorFusion() }
                }
                .font(.caption)
                .foregroundColor(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.accentColor)
                .cornerRadius(8)
            }
        }
        .padding()
        .background(cardBackgroundColor)
        .cornerRadius(12)
    }
    
    // MARK: - Sensor Data Card
    private var sensorDataCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Sensor Data")
                .font(.headline)
                .fontWeight(.semibold)
            
            if viewModel.sensorFusion.insights.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "sensor.tag")
                        .font(.title)
                        .foregroundColor(.secondary)
                    
                    Text("No sensor data available")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
            } else {
                LazyVStack(spacing: 8) {
                    ForEach(viewModel.sensorFusion.insights.prefix(3)) { insight in
                        SensorInsightRowView(insight: insight)
                    }
                    
                    if viewModel.sensorFusion.insights.count > 3 {
                        Button("View All \(viewModel.sensorFusion.insights.count) Insights") {
                            selectedTab = 2
                        }
                        .font(.caption)
                        .foregroundColor(.accentColor)
                    }
                }
            }
        }
        .padding()
        .background(cardBackgroundColor)
        .cornerRadius(12)
    }
    
    // MARK: - Fusion Insights Card
    private var fusionInsightsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Fusion Insights")
                .font(.headline)
                .fontWeight(.semibold)
            
            if viewModel.sensorFusion.insights.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "lightbulb")
                        .font(.title)
                        .foregroundColor(.secondary)
                    
                    Text("No insights available")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
            } else {
                LazyVStack(spacing: 8) {
                    ForEach(viewModel.sensorFusion.insights.prefix(3)) { insight in
                        InsightRowView(insight: insight)
                    }
                    
                    if viewModel.sensorFusion.insights.count > 3 {
                        Button("View All \(viewModel.sensorFusion.insights.count) Insights") {
                            selectedTab = 2
                        }
                        .font(.caption)
                        .foregroundColor(.accentColor)
                    }
                }
            }
        }
        .padding()
        .background(cardBackgroundColor)
        .cornerRadius(12)
    }
    
    // MARK: - Sensor Analytics Card
    private var sensorAnalyticsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Sensor Analytics")
                .font(.headline)
                .fontWeight(.semibold)
            
            if viewModel.sensorFusion.insights.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .font(.title)
                        .foregroundColor(.secondary)
                    
                    Text("No analytics data available")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
            } else {
                VStack(spacing: 12) {
                    // Insight Categories
                    HStack {
                        Text("Insight Categories")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        Spacer()
                        
                        VStack(alignment: .trailing, spacing: 4) {
                            ForEach(InsightCategory.allCases.prefix(3), id: \.self) { category in
                                let count = viewModel.sensorFusion.insights.filter { $0.category == category }.count
                                if count > 0 {
                                    Text("\(category.rawValue.capitalized): \(count)")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                    }
                    
                    // Severity Distribution
                    HStack {
                        Text("Severity Distribution")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        Spacer()
                        
                        VStack(alignment: .trailing, spacing: 4) {
                            ForEach(Severity.allCases.prefix(3), id: \.self) { severity in
                                let count = viewModel.sensorFusion.insights.filter { $0.severity == severity }.count
                                if count > 0 {
                                    Text("\(severity.rawValue.capitalized): \(count)")
                                        .font(.caption)
                                        .foregroundColor(severityColor(severity))
                                }
                            }
                        }
                    }
                }
            }
        }
        .padding()
        .background(cardBackgroundColor)
        .cornerRadius(12)
    }
    
    // MARK: - Device Analytics Card
    private var deviceAnalyticsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Device Analytics")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: 12) {
                // Device Type Distribution
                HStack {
                    Text("Device Types")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        ForEach(DeviceType.allCases.prefix(4), id: \.self) { type in
                            let count = viewModel.connectedDevices.filter { $0.type == type }.count
                            if count > 0 {
                                Text("\(type.rawValue.capitalized): \(count)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
                
                // Connection Status
                HStack {
                    Text("Connection Status")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        ForEach(DeviceStatus.allCases.prefix(3), id: \.self) { status in
                            let count = viewModel.connectedDevices.filter { $0.status == status }.count
                            if count > 0 {
                                Text("\(status.rawValue.capitalized): \(count)")
                                    .font(.caption)
                                    .foregroundColor(statusColor(status))
                            }
                        }
                    }
                }
            }
        }
        .padding()
        .background(cardBackgroundColor)
        .cornerRadius(12)
    }
    
    // MARK: - Performance Metrics Card
    private var performanceMetricsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Performance Metrics")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: 12) {
                // Integration Performance
                HStack {
                    Text("Integration Performance")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Spacer()
                    
                    Text("\(Int(viewModel.integrationProgress * 100))%")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.accentColor)
                }
                
                ProgressView(value: viewModel.integrationProgress)
                    .progressViewStyle(LinearProgressViewStyle())
                    .accentColor(.accentColor)
                
                // Device Response Time
                HStack {
                    Text("Average Response Time")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Spacer()
                    
                    Text("125ms")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(cardBackgroundColor)
        .cornerRadius(12)
    }
    
    // MARK: - Integration History Card
    private var integrationHistoryCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Integration History")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: 8) {
                ForEach(0..<3) { index in
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Integration Session \(index + 1)")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            
                            Text("2 hours ago")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        Text("\(Int.random(in: 80...100))%")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.green)
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .padding()
        .background(cardBackgroundColor)
        .cornerRadius(12)
    }
    
    // MARK: - Helper Methods
    private func tabTitle(for index: Int) -> String {
        switch index {
        case 0: return "Devices"
        case 1: return "IoT"
        case 2: return "Sensors"
        case 3: return "Analytics"
        default: return ""
        }
    }
    
    private func severityColor(_ severity: Severity) -> Color {
        switch severity {
        case .low: return .green
        case .medium: return .yellow
        case .high: return .orange
        case .critical: return .red
        }
    }
    
    private func statusColor(_ status: DeviceStatus) -> Color {
        switch status {
        case .connected: return .green
        case .disconnected: return .red
        case .connecting: return .yellow
        case .error: return .red
        case .unknown: return .gray
        }
    }
    
    // MARK: - Computed Properties
    private var backgroundColor: Color {
        colorScheme == .dark ? Color.black : Color(.systemGroupedBackground)
    }
    
    private var headerBackgroundColor: Color {
        colorScheme == .dark ? Color(.systemGray6) : Color(.systemBackground)
    }
    
    private var cardBackgroundColor: Color {
        colorScheme == .dark ? Color(.systemGray6) : Color(.systemBackground)
    }
}

// MARK: - Supporting Views

@available(iOS 18.0, macOS 15.0, *)
struct DeviceRowView: View {
    let device: HealthDevice
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                Image(systemName: deviceIcon(for: device.type))
                    .font(.title2)
                    .foregroundColor(.accentColor)
                    .frame(width: 30)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(device.name)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    
                    Text(device.manufacturer)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    Text(device.status.rawValue.capitalized)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(statusColor(device.status))
                    
                    Text(device.lastSeen, style: .relative)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func deviceIcon(for type: DeviceType) -> String {
        switch type {
        case .appleWatch: return "applewatch"
        case .iphone: return "iphone"
        case .ipad: return "ipad"
        case .mac: return "laptopcomputer"
        case .bluetooth: return "wave.3.right"
        case .wifi: return "wifi"
        case .cellular: return "antenna.radiowaves.left.and.right"
        }
    }
    
    private func statusColor(_ status: DeviceStatus) -> Color {
        switch status {
        case .connected: return .green
        case .disconnected: return .red
        case .connecting: return .yellow
        case .error: return .red
        case .unknown: return .gray
        }
    }
}

@available(iOS 18.0, macOS 15.0, *)
struct AvailableDeviceRowView: View {
    let device: HealthDevice
    let onConnect: () -> Void
    
    var body: some View {
        HStack {
            Image(systemName: deviceIcon(for: device.type))
                .font(.title2)
                .foregroundColor(.accentColor)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(device.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                
                Text(device.manufacturer)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Button("Connect") {
                onConnect()
            }
            .font(.caption)
            .foregroundColor(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color.accentColor)
            .cornerRadius(6)
        }
        .padding(.vertical, 4)
    }
    
    private func deviceIcon(for type: DeviceType) -> String {
        switch type {
        case .appleWatch: return "applewatch"
        case .iphone: return "iphone"
        case .ipad: return "ipad"
        case .mac: return "laptopcomputer"
        case .bluetooth: return "wave.3.right"
        case .wifi: return "wifi"
        case .cellular: return "antenna.radiowaves.left.and.right"
        }
    }
}

@available(iOS 18.0, macOS 15.0, *)
struct AlertRowView: View {
    let alert: DeviceAlert
    
    var body: some View {
        HStack {
            Image(systemName: severityIcon(for: alert.severity))
                .font(.title3)
                .foregroundColor(severityColor(for: alert.severity))
                .frame(width: 20)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(alert.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                
                Text(alert.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
            
            Spacer()
            
            Text(alert.timestamp, style: .relative)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
    
    private func severityIcon(for severity: AlertSeverity) -> String {
        switch severity {
        case .low: return "info.circle"
        case .medium: return "exclamationmark.triangle"
        case .high: return "exclamationmark.triangle.fill"
        case .critical: return "xmark.octagon.fill"
        }
    }
    
    private func severityColor(for severity: AlertSeverity) -> Color {
        switch severity {
        case .low: return .blue
        case .medium: return .yellow
        case .high: return .orange
        case .critical: return .red
        }
    }
}

@available(iOS 18.0, macOS 15.0, *)
struct IoTCategoryRowView: View {
    let category: IoTCategory
    let devices: [IoTDevice]
    
    var body: some View {
        HStack {
            Image(systemName: categoryIcon(for: category))
                .font(.title3)
                .foregroundColor(.accentColor)
                .frame(width: 20)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(category.rawValue.capitalized)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                
                Text("\(devices.count) devices")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                Text("\(devices.filter { $0.status == .online }.count) online")
                    .font(.caption)
                    .foregroundColor(.green)
                
                Text("\(devices.filter { $0.status == .offline }.count) offline")
                    .font(.caption)
                    .foregroundColor(.red)
            }
        }
        .padding(.vertical, 4)
    }
    
    private func categoryIcon(for category: IoTCategory) -> String {
        switch category {
        case .wearable: return "applewatch"
        case .medical: return "cross.case"
        case .fitness: return "figure.run"
        case .smartHome: return "house"
        case .environmental: return "leaf"
        }
    }
}

@available(iOS 18.0, macOS 15.0, *)
struct SensorInsightRowView: View {
    let insight: SensorInsight
    
    var body: some View {
        HStack {
            Image(systemName: categoryIcon(for: insight.category))
                .font(.title3)
                .foregroundColor(.accentColor)
                .frame(width: 20)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(insight.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                
                Text(insight.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
            
            Spacer()
            
            Text(insight.timestamp, style: .relative)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
    
    private func categoryIcon(for category: InsightCategory) -> String {
        switch category {
        case .health: return "heart"
        case .activity: return "figure.run"
        case .sleep: return "bed.double"
        case .environmental: return "leaf"
        case .biometric: return "cross.case"
        case .location: return "location"
        }
    }
}

@available(iOS 18.0, macOS 15.0, *)
struct InsightRowView: View {
    let insight: SensorInsight
    
    var body: some View {
        HStack {
            Image(systemName: severityIcon(for: insight.severity))
                .font(.title3)
                .foregroundColor(severityColor(for: insight.severity))
                .frame(width: 20)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(insight.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                
                Text(insight.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
            
            Spacer()
            
            Text(insight.timestamp, style: .relative)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
    
    private func severityIcon(for severity: Severity) -> String {
        switch severity {
        case .low: return "info.circle"
        case .medium: return "exclamationmark.triangle"
        case .high: return "exclamationmark.triangle.fill"
        case .critical: return "xmark.octagon.fill"
        }
    }
    
    private func severityColor(for severity: Severity) -> Color {
        switch severity {
        case .low: return .green
        case .medium: return .yellow
        case .high: return .orange
        case .critical: return .red
        }
    }
}

// MARK: - Preview
@available(iOS 18.0, macOS 15.0, *)
#Preview {
    AdvancedHealthDeviceIntegrationDashboardView()
} 