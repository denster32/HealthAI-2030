import SwiftUI
import Charts

struct TVOSContentView: View {
    @StateObject private var healthDataManager = HealthDataManager.shared
    @StateObject private var analyticsEngine = AnalyticsEngine.shared
    @StateObject private var environmentManager = EnvironmentManager.shared
    @StateObject private var performanceManager = PerformanceOptimizationManager.shared
    @StateObject private var smartHomeManager = SmartHomeManager.shared
    
    @State private var selectedTab: TVOSTab = .overview
    @State private var isFullScreenMode = false
    @State private var autoRotateTimer: Timer?
    
    var body: some View {
        GeometryReader { geometry in
            HStack(spacing: 0) {
                // Side Navigation
                if !isFullScreenMode {
                    TVOSSideNav(selectedTab: $selectedTab)
                        .frame(width: 300)
                        .background(Color(.systemGray6))
                }
                
                // Main Content Area
                VStack(spacing: 0) {
                    // Top Bar
                    if !isFullScreenMode {
                        TVOSTopBar(
                            selectedTab: selectedTab,
                            isFullScreenMode: $isFullScreenMode
                        )
                        .frame(height: 80)
                        .background(Color(.systemBackground))
                    }
                    
                    // Main Dashboard Content
                    TVOSMainContent(selectedTab: selectedTab)
                        .background(Color(.systemGray6))
                }
            }
        }
        .onAppear {
            setupAutoRotation()
        }
        .onDisappear {
            autoRotateTimer?.invalidate()
        }
        .focusable()
        .onExitCommand {
            if isFullScreenMode {
                isFullScreenMode = false
            }
        }
    }
    
    private func setupAutoRotation() {
        // Auto-rotate through different views every 30 seconds in ambient mode
        autoRotateTimer = Timer.scheduledTimer(withTimeInterval: 30.0, repeats: true) { _ in
            if isFullScreenMode {
                rotateToNextView()
            }
        }
    }
    
    private func rotateToNextView() {
        let allTabs = TVOSTab.allCases
        if let currentIndex = allTabs.firstIndex(of: selectedTab) {
            let nextIndex = (currentIndex + 1) % allTabs.count
            selectedTab = allTabs[nextIndex]
        }
    }
}

// MARK: - Side Navigation

struct TVOSSideNav: View {
    @Binding var selectedTab: TVOSTab
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // App Title
            VStack(alignment: .leading, spacing: 8) {
                Text("HealthAI 2030")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Text("Home Dashboard")
                    .font(.title3)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 30)
            .padding(.top, 40)
            
            Divider()
                .padding(.horizontal, 20)
            
            // Navigation Items
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(TVOSTab.allCases, id: \.self) { tab in
                        TVOSNavItem(
                            tab: tab,
                            isSelected: selectedTab == tab
                        ) {
                            selectedTab = tab
                        }
                    }
                }
                .padding(.horizontal, 20)
            }
            
            Spacer()
            
            // System Status
            TVOSSystemStatus()
                .padding(.horizontal, 20)
                .padding(.bottom, 40)
        }
        .background(Color(.systemGray6))
    }
}

struct TVOSNavItem: View {
    let tab: TVOSTab
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: tab.icon)
                    .font(.title2)
                    .foregroundColor(iconColor)
                    .frame(width: 30)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(tab.title)
                        .font(.title3)
                        .fontWeight(isSelected ? .semibold : .regular)
                    
                    Text(tab.subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                if isSelected {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.accentColor)
                        .frame(width: 4, height: 40)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.accentColor.opacity(0.1) : Color.clear)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .focusable()
    }
    
    private var iconColor: Color {
        isSelected ? .accentColor : .primary
    }
}

// MARK: - Top Bar

struct TVOSTopBar: View {
    let selectedTab: TVOSTab
    @Binding var isFullScreenMode: Bool
    @ObservedObject private var healthDataManager = HealthDataManager.shared
    
    var body: some View {
        HStack {
            // Current View Title
            VStack(alignment: .leading, spacing: 4) {
                Text(selectedTab.title)
                    .font(.title)
                    .fontWeight(.semibold)
                
                Text(selectedTab.subtitle)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Quick Stats
            HStack(spacing: 40) {
                QuickStat(
                    title: "Heart Rate",
                    value: "\(Int(healthDataManager.currentHeartRate))",
                    unit: "BPM",
                    color: .red
                )
                
                QuickStat(
                    title: "HRV",
                    value: "\(Int(healthDataManager.currentHRV))",
                    unit: "ms",
                    color: .green
                )
                
                QuickStat(
                    title: "O₂ Sat",
                    value: "\(Int(healthDataManager.currentOxygenSaturation * 100))",
                    unit: "%",
                    color: .blue
                )
            }
            
            Spacer()
            
            // Full Screen Toggle
            Button(action: { isFullScreenMode.toggle() }) {
                Image(systemName: isFullScreenMode ? "arrow.down.right.and.arrow.up.left" : "arrow.up.left.and.arrow.down.right")
                    .font(.title2)
                    .foregroundColor(.primary)
                    .padding(12)
                    .background(Color(.systemGray5))
                    .clipShape(Circle())
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(.horizontal, 40)
        .padding(.vertical, 20)
    }
}

struct QuickStat: View {
    let title: String
    let value: String
    let unit: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            
            HStack(alignment: .bottom, spacing: 4) {
                Text(value)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(color)
                
                Text(unit)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}

// MARK: - Main Content

struct TVOSMainContent: View {
    let selectedTab: TVOSTab
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 30) {
                switch selectedTab {
                case .overview:
                    TVOSOverviewDashboard()
                case .health:
                    TVOSHealthDashboard()
                case .environment:
                    TVOSEnvironmentDashboard()
                case .family:
                    TVOSFamilyDashboard()
                case .analytics:
                    TVOSAnalyticsDashboard()
                case .alerts:
                    TVOSAlertsDashboard()
                case .ambient:
                    TVOSAmbientDashboard()
                }
            }
            .padding(40)
        }
    }
}

// MARK: - Dashboard Views

struct TVOSOverviewDashboard: View {
    @ObservedObject private var healthDataManager = HealthDataManager.shared
    @ObservedObject private var analyticsEngine = AnalyticsEngine.shared
    @ObservedObject private var environmentManager = EnvironmentManager.shared
    
    var body: some View {
        LazyVGrid(columns: [
            GridItem(.flexible(), spacing: 30),
            GridItem(.flexible(), spacing: 30),
            GridItem(.flexible(), spacing: 30)
        ], spacing: 30) {
            // Primary Health Card
            TVOSLargeCard(
                title: "Health Overview",
                icon: "heart.fill",
                color: .red
            ) {
                VStack(spacing: 20) {
                    HStack(spacing: 40) {
                        TVOSMetric(
                            title: "Heart Rate",
                            value: "\(Int(healthDataManager.currentHeartRate))",
                            unit: "BPM",
                            color: .red,
                            trend: .stable
                        )
                        
                        TVOSMetric(
                            title: "HRV",
                            value: "\(Int(healthDataManager.currentHRV))",
                            unit: "ms",
                            color: .green,
                            trend: .increasing
                        )
                    }
                    
                    HStack(spacing: 40) {
                        TVOSMetric(
                            title: "Oxygen",
                            value: "\(Int(healthDataManager.currentOxygenSaturation * 100))",
                            unit: "%",
                            color: .blue,
                            trend: .stable
                        )
                        
                        TVOSMetric(
                            title: "Steps",
                            value: "\(healthDataManager.stepCount)",
                            unit: "",
                            color: .orange,
                            trend: .increasing
                        )
                    }
                }
            }
            
            // PhysioForecast Card
            TVOSLargeCard(
                title: "PhysioForecast",
                icon: "brain.head.profile",
                color: .purple
            ) {
                if let forecast = analyticsEngine.physioForecast {
                    VStack(spacing: 16) {
                        TVOSForecastBar(
                            title: "Energy",
                            value: forecast.energy,
                            color: .red
                        )
                        
                        TVOSForecastBar(
                            title: "Mood",
                            value: forecast.moodStability,
                            color: .blue
                        )
                        
                        TVOSForecastBar(
                            title: "Cognitive",
                            value: forecast.cognitiveAcuity,
                            color: .purple
                        )
                        
                        TVOSForecastBar(
                            title: "Recovery",
                            value: forecast.musculoskeletalResilience,
                            color: .green
                        )
                    }
                } else {
                    Text("Generating forecast...")
                        .font(.title2)
                        .foregroundColor(.secondary)
                }
            }
            
            // Environment Card
            TVOSLargeCard(
                title: "Environment",
                icon: "house.fill",
                color: .green
            ) {
                VStack(spacing: 16) {
                    HStack(spacing: 30) {
                        TVOSEnvironmentMetric(
                            title: "Temperature",
                            value: "\(String(format: "%.1f", environmentManager.currentTemperature))°C",
                            icon: "thermometer",
                            color: .orange
                        )
                        
                        TVOSEnvironmentMetric(
                            title: "Humidity",
                            value: "\(Int(environmentManager.currentHumidity))%",
                            icon: "humidity.fill",
                            color: .blue
                        )
                    }
                    
                    HStack(spacing: 30) {
                        TVOSEnvironmentMetric(
                            title: "Air Quality",
                            value: "\(Int(environmentManager.airQuality * 100))%",
                            icon: "wind",
                            color: .green
                        )
                        
                        TVOSEnvironmentMetric(
                            title: "Light",
                            value: "\(Int(environmentManager.currentLightLevel * 100))%",
                            icon: "lightbulb.fill",
                            color: .yellow
                        )
                    }
                }
            }
        }
    }
}

struct TVOSHealthDashboard: View {
    @ObservedObject private var healthDataManager = HealthDataManager.shared
    @ObservedObject private var analyticsEngine = AnalyticsEngine.shared
    
    var body: some View {
        LazyVGrid(columns: [
            GridItem(.flexible(), spacing: 30),
            GridItem(.flexible(), spacing: 30)
        ], spacing: 30) {
            // Detailed Health Metrics
            TVOSLargeCard(
                title: "Vital Signs",
                icon: "waveform.path.ecg",
                color: .red
            ) {
                VStack(spacing: 20) {
                    HStack(spacing: 40) {
                        TVOSDetailedMetric(
                            title: "Heart Rate",
                            currentValue: "\(Int(healthDataManager.currentHeartRate))",
                            unit: "BPM",
                            range: "Resting: 45-65",
                            color: .red
                        )
                        
                        TVOSDetailedMetric(
                            title: "Blood Pressure",
                            currentValue: "120/80",
                            unit: "mmHg",
                            range: "Normal: <120/80",
                            color: .blue
                        )
                    }
                    
                    HStack(spacing: 40) {
                        TVOSDetailedMetric(
                            title: "HRV",
                            currentValue: "\(Int(healthDataManager.currentHRV))",
                            unit: "ms",
                            range: "Good: >40ms",
                            color: .green
                        )
                        
                        TVOSDetailedMetric(
                            title: "Respiratory Rate",
                            currentValue: "16",
                            unit: "/min",
                            range: "Normal: 12-20",
                            color: .cyan
                        )
                    }
                }
            }
            
            // Health Trends Chart
            TVOSLargeCard(
                title: "Health Trends",
                icon: "chart.line.uptrend.xyaxis",
                color: .blue
            ) {
                Chart {
                    ForEach(0..<24, id: \.self) { hour in
                        LineMark(
                            x: .value("Hour", hour),
                            y: .value("Heart Rate", Double.random(in: 60...80))
                        )
                        .foregroundStyle(.red)
                        
                        LineMark(
                            x: .value("Hour", hour),
                            y: .value("HRV", Double.random(in: 30...50))
                        )
                        .foregroundStyle(.green)
                    }
                }
                .frame(height: 200)
                .chartLegend(position: .bottom)
            }
        }
    }
}

struct TVOSEnvironmentDashboard: View {
    @ObservedObject private var environmentManager = EnvironmentManager.shared
    @ObservedObject private var smartHomeManager = SmartHomeManager.shared
    
    var body: some View {
        LazyVGrid(columns: [
            GridItem(.flexible(), spacing: 30),
            GridItem(.flexible(), spacing: 30)
        ], spacing: 30) {
            // Environment Controls
            TVOSLargeCard(
                title: "Environment Control",
                icon: "slider.horizontal.3",
                color: .blue
            ) {
                VStack(spacing: 20) {
                    TVOSEnvironmentControl(
                        title: "Temperature",
                        currentValue: environmentManager.currentTemperature,
                        targetValue: 22.0,
                        unit: "°C",
                        range: 18...26,
                        color: .orange
                    )
                    
                    TVOSEnvironmentControl(
                        title: "Humidity",
                        currentValue: environmentManager.currentHumidity,
                        targetValue: 45.0,
                        unit: "%",
                        range: 30...60,
                        color: .blue
                    )
                    
                    TVOSEnvironmentControl(
                        title: "Light Level",
                        currentValue: environmentManager.currentLightLevel * 100,
                        targetValue: 75.0,
                        unit: "%",
                        range: 0...100,
                        color: .yellow
                    )
                }
            }
            
            // Smart Home Status
            TVOSLargeCard(
                title: "Smart Home",
                icon: "homekit",
                color: .green
            ) {
                VStack(spacing: 16) {
                    TVOSSmartHomeDevice(
                        name: "Living Room Lights",
                        status: "On",
                        value: "75%",
                        icon: "lightbulb.fill",
                        color: .yellow
                    )
                    
                    TVOSSmartHomeDevice(
                        name: "Thermostat",
                        status: "Auto",
                        value: "22°C",
                        icon: "thermometer",
                        color: .orange
                    )
                    
                    TVOSSmartHomeDevice(
                        name: "Air Purifier",
                        status: "Running",
                        value: "Level 2",
                        icon: "wind",
                        color: .blue
                    )
                    
                    TVOSSmartHomeDevice(
                        name: "Security System",
                        status: "Armed",
                        value: "Home",
                        icon: "shield.fill",
                        color: .green
                    )
                }
            }
        }
    }
}

struct TVOSFamilyDashboard: View {
    var body: some View {
        LazyVGrid(columns: [
            GridItem(.flexible(), spacing: 30),
            GridItem(.flexible(), spacing: 30),
            GridItem(.flexible(), spacing: 30)
        ], spacing: 30) {
            // Family Member Cards
            TVOSFamilyMemberCard(
                name: "John",
                status: "Sleeping",
                heartRate: 58,
                sleepStage: "Deep Sleep",
                color: .blue
            )
            
            TVOSFamilyMemberCard(
                name: "Sarah",
                status: "Awake",
                heartRate: 72,
                sleepStage: "Active",
                color: .green
            )
            
            TVOSFamilyMemberCard(
                name: "Emma",
                status: "Light Sleep",
                heartRate: 65,
                sleepStage: "REM",
                color: .purple
            )
        }
    }
}

struct TVOSAnalyticsDashboard: View {
    @ObservedObject private var analyticsEngine = AnalyticsEngine.shared
    
    var body: some View {
        LazyVGrid(columns: [
            GridItem(.flexible(), spacing: 30),
            GridItem(.flexible(), spacing: 30)
        ], spacing: 30) {
            // Sleep Analytics
            TVOSLargeCard(
                title: "Sleep Analytics",
                icon: "bed.double.fill",
                color: .purple
            ) {
                VStack(spacing: 16) {
                    HStack(spacing: 30) {
                        TVOSSleepMetric(
                            title: "Total Sleep",
                            value: "7h 32m",
                            target: "8h",
                            color: .blue
                        )
                        
                        TVOSSleepMetric(
                            title: "Deep Sleep",
                            value: "1h 45m",
                            target: "2h",
                            color: .indigo
                        )
                    }
                    
                    HStack(spacing: 30) {
                        TVOSSleepMetric(
                            title: "REM Sleep",
                            value: "1h 20m",
                            target: "1.5h",
                            color: .purple
                        )
                        
                        TVOSSleepMetric(
                            title: "Sleep Efficiency",
                            value: "92%",
                            target: "85%",
                            color: .green
                        )
                    }
                }
            }
            
            // Activity Analytics
            TVOSLargeCard(
                title: "Activity Analytics",
                icon: "figure.walk",
                color: .orange
            ) {
                VStack(spacing: 16) {
                    Chart {
                        ForEach(0..<7, id: \.self) { day in
                            BarMark(
                                x: .value("Day", day),
                                y: .value("Steps", Double.random(in: 5000...15000))
                            )
                            .foregroundStyle(.orange)
                        }
                    }
                    .frame(height: 200)
                    
                    HStack(spacing: 30) {
                        TVOSActivityMetric(
                            title: "Steps Today",
                            value: "12,450",
                            goal: "10,000",
                            color: .orange
                        )
                        
                        TVOSActivityMetric(
                            title: "Active Calories",
                            value: "420",
                            goal: "500",
                            color: .red
                        )
                    }
                }
            }
        }
    }
}

struct TVOSAlertsDashboard: View {
    @ObservedObject private var analyticsEngine = AnalyticsEngine.shared
    
    var body: some View {
        VStack(spacing: 30) {
            // Critical Alerts
            TVOSLargeCard(
                title: "Health Alerts",
                icon: "exclamationmark.triangle.fill",
                color: .red
            ) {
                if analyticsEngine.healthAlerts.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.green)
                        
                        Text("All Systems Normal")
                            .font(.title2)
                            .fontWeight(.semibold)
                        
                        Text("No active health alerts")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                } else {
                    VStack(spacing: 12) {
                        ForEach(analyticsEngine.healthAlerts.prefix(5), id: \.timestamp) { alert in
                            TVOSAlertRow(alert: alert)
                        }
                    }
                }
            }
            
            // System Notifications
            TVOSLargeCard(
                title: "System Status",
                icon: "gear",
                color: .blue
            ) {
                VStack(spacing: 12) {
                    TVOSSystemAlert(
                        title: "Data Sync",
                        message: "All devices synchronized",
                        status: .normal,
                        icon: "icloud.and.arrow.up"
                    )
                    
                    TVOSSystemAlert(
                        title: "Network Connection",
                        message: "Connected to WiFi",
                        status: .normal,
                        icon: "wifi"
                    )
                    
                    TVOSSystemAlert(
                        title: "Battery Status",
                        message: "All devices charged",
                        status: .normal,
                        icon: "battery.100"
                    )
                }
            }
        }
    }
}

struct TVOSAmbientDashboard: View {
    @ObservedObject private var healthDataManager = HealthDataManager.shared
                }
            }
        }
    }
}

struct TVOSAmbientDashboard: View {
    @ObservedObject private var healthDataManager = HealthDataManager.shared
    @ObservedObject private var environmentManager = EnvironmentManager.shared
    
    var body: some View {
        VStack(spacing: 0) {
            // Large Time Display
            VStack(spacing: 16) {
                Text(Date().formatted(.dateTime.hour().minute()))
                    .font(.system(size: 120, weight: .ultraLight, design: .rounded))
                    .foregroundColor(.primary)
                
                Text(Date().formatted(.dateTime.weekday(.wide).month().day()))
                    .font(.title)
                    .foregroundColor(.secondary)
            }
            .padding(.top, 60)
            
            Spacer()
            
            // Ambient Health Indicators
            HStack(spacing: 80) {
                TVOSAmbientIndicator(
                    title: "Heart Rate",
                    value: "\(Int(healthDataManager.currentHeartRate))",
                    unit: "BPM",
                    icon: "heart.fill",
                    color: .red
                )
                
                TVOSAmbientIndicator(
                    title: "Temperature",
                    value: String(format: "%.1f", environmentManager.currentTemperature),
                    unit: "°C",
                    icon: "thermometer",
                    color: .orange
                )
                
                TVOSAmbientIndicator(
                    title: "Sleep Quality",
                    value: "92",
                    unit: "%",
                    icon: "bed.double.fill",
                    color: .purple
                )
            }
            .padding(.bottom, 80)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Supporting Views

struct TVOSLargeCard<Content: View>: View {
    let title: String
    let icon: String
    let color: Color
    let content: Content
    
    init(title: String, icon: String, color: Color, @ViewBuilder content: () -> Content) {
        self.title = title
        self.icon = icon
        self.color = color
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.title)
                    .foregroundColor(color)
                
                Text(title)
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Spacer()
            }
            
            content
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(30)
        .background(Color(.systemBackground))
        .cornerRadius(20)
        .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
    }
}

struct TVOSMetric: View {
    let title: String
    let value: String
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Image(systemName: trend.icon)
                    .font(.caption)
                    .foregroundColor(trend.color)
            }
            
            HStack(alignment: .bottom, spacing: 4) {
                Text(value)
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(color)
                
                Text(unit)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct TVOSForecastBar: View {
    let title: String
    let value: Double
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Text("\(Int(value * 100))%")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(color)
            }
            
            ProgressView(value: value)
                .progressViewStyle(LinearProgressViewStyle(tint: color))
                .frame(height: 8)
                .cornerRadius(4)
        }
    }
}

struct TVOSEnvironmentMetric: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(value)
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

struct TVOSDetailedMetric: View {
    let title: String
    let currentValue: String
    let unit: String
    let range: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            HStack(alignment: .bottom, spacing: 4) {
                Text(currentValue)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(color)
                
                Text(unit)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Text(range)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct TVOSEnvironmentControl: View {
    let title: String
    let currentValue: Double
    let targetValue: Double
    let unit: String
    let range: ClosedRange<Double>
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text("\(String(format: "%.1f", currentValue))\(unit)")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(color)
            }
            
            HStack(spacing: 12) {
                Text("\(String(format: "%.0f", range.lowerBound))")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                ProgressView(
                    value: (currentValue - range.lowerBound) / (range.upperBound - range.lowerBound)
                )
                .progressViewStyle(LinearProgressViewStyle(tint: color))
                .frame(height: 6)
                
                Text("\(String(format: "%.0f", range.upperBound))")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Text("Target: \(String(format: "%.1f", targetValue))\(unit)")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
    }
}

struct TVOSSmartHomeDevice: View {
    let name: String
    let status: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                
                Text(status)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Text(value)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(color)
        }
        .padding(.vertical, 8)
    }
}

struct TVOSFamilyMemberCard: View {
    let name: String
    let status: String
    let heartRate: Int
    let sleepStage: String
    let color: Color
    
    var body: some View {
        TVOSLargeCard(
            title: name,
            icon: "person.fill",
            color: color
        ) {
            VStack(spacing: 16) {
                Text(status)
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(color)
                
                VStack(spacing: 8) {
                    HStack {
                        Text("Heart Rate")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        Text("\(heartRate) BPM")
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }
                    
                    HStack {
                        Text("Sleep Stage")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        Text(sleepStage)
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }
                }
            }
        }
    }
}

struct TVOSSleepMetric: View {
    let title: String
    let value: String
    let target: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(color)
            
            Text("Target: \(target)")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
    }
}

struct TVOSActivityMetric: View {
    let title: String
    let value: String
    let goal: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(color)
            
            Text("Goal: \(goal)")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
    }
}

struct TVOSAlertRow: View {
    let alert: HealthAlert
    
    var body: some View {
        HStack(spacing: 16) {
            Circle()
                .fill(severityColor)
                .frame(width: 12, height: 12)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(alert.message)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                
                Text(alert.recommendedAction)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Text(alert.timestamp.formatted(.dateTime.hour().minute()))
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 8)
    }
    
    private var severityColor: Color {
        switch alert.severity {
        case .low: return .green
        case .medium: return .orange
        case .high: return .red
        case .critical: return .purple
        }
    }
}

struct TVOSSystemAlert: View {
    let title: String
    let message: String
    let status: SystemStatus
    let icon: String
    
    enum SystemStatus {
        case normal, warning, error
        
        var color: Color {
            switch self {
            case .normal: return .green
            case .warning: return .orange
            case .error: return .red
            }
        }
    }
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(status.color)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                
                Text(message)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Circle()
                .fill(status.color)
                .frame(width: 8, height: 8)
        }
        .padding(.vertical, 8)
    }
}

struct TVOSAmbientIndicator: View {
    let title: String
    let value: String
    let unit: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: icon)
                .font(.system(size: 48))
                .foregroundColor(color)
            
            VStack(spacing: 8) {
                HStack(alignment: .bottom, spacing: 8) {
                    Text(value)
                        .font(.system(size: 48, weight: .light, design: .rounded))
                        .foregroundColor(.primary)
                    
                    Text(unit)
                        .font(.title2)
                        .foregroundColor(.secondary)
                }
                
                Text(title)
                    .font(.title3)
                    .foregroundColor(.secondary)
            }
        }
    }
}

struct TVOSSystemStatus: View {
    @ObservedObject private var performanceManager = PerformanceOptimizationManager.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("System Status")
                .font(.caption)
                .foregroundColor(.secondary)
                .textCase(.uppercase)
            
            VStack(spacing: 8) {
                HStack {
                    Circle()
                        .fill(.green)
                        .frame(width: 8, height: 8)
                    
                    Text("Network Connected")
                        .font(.caption)
                        .foregroundColor(.primary)
                    
                    Spacer()
                }
                
                HStack {
                    Circle()
                        .fill(batteryColor)
                        .frame(width: 8, height: 8)
                    
                    Text("Battery \(Int(performanceManager.batteryLevel * 100))%")
                        .font(.caption)
                        .foregroundColor(.primary)
                    
                    Spacer()
                }
                
                HStack {
                    Circle()
                        .fill(.blue)
                        .frame(width: 8, height: 8)
                    
                    Text("Data Synced")
                        .font(.caption)
                        .foregroundColor(.primary)
                    
                    Spacer()
                }
            }
        }
    }
    
    private var batteryColor: Color {
        let level = performanceManager.batteryLevel
        if level > 0.5 { return .green }
        else if level > 0.2 { return .orange }
        else { return .red }
    }
}

// MARK: - Enums

enum TVOSTab: String, CaseIterable {
    case overview = "overview"
    case health = "health"
    case environment = "environment"
    case family = "family"
    case analytics = "analytics"
    case alerts = "alerts"
    case ambient = "ambient"
    
    var title: String {
        switch self {
        case .overview: return "Overview"
        case .health: return "Health Monitoring"
        case .environment: return "Environment"
        case .family: return "Family Health"
        case .analytics: return "Analytics"
        case .alerts: return "Alerts & Status"
        case .ambient: return "Ambient Display"
        }
    }
    
    var subtitle: String {
        switch self {
        case .overview: return "Complete health dashboard"
        case .health: return "Detailed vital signs"
        case .environment: return "Home environment control"
        case .family: return "Family member tracking"
        case .analytics: return "Sleep and activity analysis"
        case .alerts: return "Health alerts and notifications"
        case .ambient: return "Always-on display mode"
        }
    }
    
    var icon: String {
        switch self {
        case .overview: return "house.fill"
        case .health: return "heart.fill"
        case .environment: return "leaf.fill"
        case .family: return "person.3.fill"
        case .analytics: return "chart.bar.fill"
        case .alerts: return "bell.fill"
        case .ambient: return "moon.fill"
        }
    }
}

#Preview {
    TVOSContentView()
}